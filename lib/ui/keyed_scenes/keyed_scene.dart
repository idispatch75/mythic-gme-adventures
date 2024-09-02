import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../../persisters/persister.dart';

class KeyedScene {
  String trigger;
  String event;
  List<KeyedSceneCount> counts;

  KeyedScene({
    required this.trigger,
    required this.event,
    List<KeyedSceneCount>? counts,
  }) : counts = counts ?? List.filled(2, KeyedSceneCount(count: 0));

  Map<String, dynamic> toJson() => {
        'trigger': trigger,
        'event': event,
        'counts': counts,
      };

  KeyedScene.fromJson(Map<String, dynamic> json)
      : this(
          trigger: json['trigger'],
          event: json['event'],
          counts: fromJsonList(json['counts'], KeyedSceneCount.fromJson),
        );
}

class KeyedSceneCount {
  int count;

  KeyedSceneCount({required this.count});

  Map<String, dynamic> toJson() => {
        'count': count,
      };

  KeyedSceneCount.fromJson(Map<String, dynamic> json)
      : this(count: json['count']);
}

class KeyedScenesService extends GetxService with SavableMixin {
  static const _collectionKey = 'keyedScenes';

  final scenes = <Rx<KeyedScene>>[].obs;

  KeyedScenesService();

  void add(KeyedScene scene) {
    scenes.add(scene.obs);

    requestSave();
  }

  void delete(KeyedScene scene) {
    scenes.removeWhere((e) => e.value == scene);

    requestSave();
  }

  Map<String, dynamic> toJson() => {
        _collectionKey: scenes,
      };

  KeyedScenesService.fromJson(Map<String, dynamic> json) {
    for (var item in fromJsonList(json[_collectionKey], KeyedScene.fromJson)) {
      add(item);
    }
  }
}
