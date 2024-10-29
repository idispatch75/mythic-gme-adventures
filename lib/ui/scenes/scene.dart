import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../persisters/persister.dart';

class Scene {
  String summary;
  String? notes;

  Scene({required this.summary, this.notes});

  JsonObj toJson() => {
        'summary': summary,
        if (notes != null) 'notes': notes,
      };

  Scene.fromJson(JsonObj json)
      : this(summary: json['summary'], notes: json['notes']);
}

class ScenesService extends GetxService with SavableMixin {
  final scenes = <Rx<Scene>>[].obs;

  ScenesService();

  void add(Scene scene) {
    scenes.add(scene.obs);

    requestSave();
  }

  void delete(Scene scene) {
    scenes.removeWhere((e) => e.value == scene);

    requestSave();
  }

  JsonObj toJson() => {
        'scenes': scenes,
      };

  ScenesService.fromJson(JsonObj json) {
    for (var item in fromJsonList(json['scenes'], Scene.fromJson)) {
      add(item);
    }
  }
}
