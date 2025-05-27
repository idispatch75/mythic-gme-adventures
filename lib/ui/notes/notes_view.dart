import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/get_extensions.dart';
import '../../helpers/list_view_utils.dart';
import '../layouts/layout.dart';
import '../styles.dart';
import '../widgets/button_row.dart';
import 'note.dart';
import 'note_edit_page_view.dart' show NoteEditPageService;
import 'note_edit_view.dart';

class NotesView extends GetView<NotesService> {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ButtonRow(
          children: [
            IconButton.filled(
              onPressed: _create,
              icon: const Icon(Icons.add),
              tooltip: 'Create a Note',
            ),
          ],
        ),
        Expanded(
          child: Obx(
            () => defaultReorderableListView(
              items: controller.notes(),
              itemBuilder: (_, item, __) {
                return _NoteView(item);
              },
              removedItemBuilder: (_, item) {
                return _NoteView(item, isDeleted: true);
              },
              onReorderFinished: controller.replaceAll,
            ),
          ),
        ),
      ],
    );
  }

  void _create() async {
    final note = Note('');

    final result = await Get.dialog<bool>(
      NoteEditView(note, isNew: true),
      barrierDismissible: false,
    );

    if (result ?? false) {
      controller.add(note);
    }
  }
}

class _NoteView extends GetView<NotesService> {
  final Rx<Note> _note;
  final bool isDeleted;

  const _NoteView(this._note, {this.isDeleted = false});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListTile(
        contentPadding: AppStyles.listTileTitlePadding,
        title: Text(_note().title),
        onTap: !isDeleted ? _edit : null,
        trailing: !isDeleted
            ? IconButton(
                onPressed: _editFullscreen,
                icon: const Icon(Icons.fullscreen),
                tooltip: 'Full screen edition',
              )
            : null,
      ),
    );
  }

  void _edit() async {
    final result = await Get.dialog<bool>(
      NoteEditView(_note(), isNew: false),
      barrierDismissible: false,
    );

    if (result ?? false) {
      _note.refresh();

      controller.requestSave();
    }
  }

  void _editFullscreen() {
    final temporaryData = Note(
      _note.value.title,
      content: _note.value.content,
    );
    Get.replaceForced(
      NoteEditPageService(
        _note.value,
        temporaryData: temporaryData,
        isNew: false,
      ),
    );
    Get.find<LayoutController>().hasEditNotePage.value = true;
  }
}
