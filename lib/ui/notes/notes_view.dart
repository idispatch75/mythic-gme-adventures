import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../widgets/button_row.dart';
import 'note.dart';
import 'note_edit_view.dart';

class NotesView extends GetView<NotesService> {
  const NotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final notes = controller.notes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ButtonRow(children: [
          IconButton.filled(
            onPressed: _create,
            icon: const Icon(Icons.add),
            tooltip: 'Create a Note',
          ),
        ]),
        Expanded(
          child: Obx(
            () => defaultListView(
              itemCount: notes.length,
              itemBuilder: (_, index) {
                return _NoteView(notes[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _create() async {
    final note = Note('');

    final result = await Get.dialog<bool>(
      NoteEditView(note, canDelete: false),
      barrierDismissible: false,
    );

    if (result ?? false) {
      controller.add(note);
    }
  }
}

class _NoteView extends GetView<NotesService> {
  final Rx<Note> _note;

  const _NoteView(this._note);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListTile(
        title: Text(_note().title),
        onTap: _edit,
      ),
    );
  }

  void _edit() async {
    final result = await Get.dialog<bool>(
      NoteEditView(_note(), canDelete: true),
      barrierDismissible: false,
    );

    if (result ?? false) {
      _note.refresh();

      controller.requestSave();
    }
  }
}
