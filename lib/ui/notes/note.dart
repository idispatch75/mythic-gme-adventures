import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../../persisters/persister.dart';

class Note {
  String title;
  String? content;

  Note(this.title, {this.content});

  Map<String, dynamic> toJson() => {
        'title': title,
        if (content != null) 'content': content,
      };

  Note.fromJson(Map<String, dynamic> json)
      : this(json['title'], content: json['content']);
}

class NotesService extends GetxService with SavableMixin {
  var notes = <Rx<Note>>[].obs;

  NotesService();

  void add(Note note) {
    notes.add(note.obs);

    requestSave();
  }

  void delete(Note note) {
    notes.removeWhere((e) => e.value == note);

    requestSave();
  }

  Map<String, dynamic> toJson() => {
        'notes': notes,
      };

  NotesService.fromJson(Map<String, dynamic> json) {
    for (var item in fromJsonList(json['notes'], Note.fromJson)) {
      add(item);
    }
  }
}
