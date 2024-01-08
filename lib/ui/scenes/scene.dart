import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../../persisters/persister.dart';

class Scene {
  String summary;
  String? notes;

  Scene({required this.summary, this.notes});

  Map<String, dynamic> toJson() => {
        'summary': summary,
        if (notes != null) 'notes': notes,
      };

  Scene.fromJson(Map<String, dynamic> json)
      : this(summary: json['summary'], notes: json['notes']);
}

class ScenesService extends GetxService with SavableMixin {
  var scenes = <Rx<Scene>>[].obs;

  ScenesService();

  void add(Scene scene) {
    scenes.add(scene.obs);

    requestSave();
  }

  void delete(Scene scene) {
    scenes.removeWhere((e) => e.value == scene);

    requestSave();
  }

  Map<String, dynamic> toJson() => {
        'scenes': scenes,
      };

  ScenesService.fromJson(Map<String, dynamic> json) {
    for (var item in fromJsonList(json['scenes'], Scene.fromJson)) {
      add(item);
    }
  }
}
