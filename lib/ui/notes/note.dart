import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../helpers/rx_list_extensions.dart';
import '../../persisters/persister.dart';

class Note {
  String title;
  String? content;

  Note(this.title, {this.content});

  JsonObj toJson() => {
        'title': title,
        if (content != null) 'content': content,
      };

  Note.fromJson(JsonObj json) : this(json['title'], content: json['content']);
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

  void replaceAll(List<Rx<Note>> newNotes) {
    notes.replaceAll(newNotes);

    requestSave();
  }

  JsonObj toJson() => {
        'notes': notes,
      };

  NotesService.fromJson(JsonObj json) {
    for (var item in fromJsonList(json['notes'], Note.fromJson)) {
      add(item);
    }
  }
}
