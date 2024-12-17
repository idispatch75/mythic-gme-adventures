import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../helpers/rx_list_extensions.dart';
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

  JsonObj toJson() => {
        'trigger': trigger,
        'event': event,
        'counts': counts,
      };

  KeyedScene.fromJson(JsonObj json)
      : this(
          trigger: json['trigger'],
          event: json['event'],
          counts: fromJsonList(json['counts'], KeyedSceneCount.fromJson),
        );
}

class KeyedSceneCount {
  int count;

  KeyedSceneCount({required this.count});

  JsonObj toJson() => {
        'count': count,
      };

  KeyedSceneCount.fromJson(JsonObj json) : this(count: json['count']);
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

  void replaceAll(List<Rx<KeyedScene>> newScenes) {
    scenes.replaceAll(newScenes);

    requestSave();
  }

  JsonObj toJson() => {
        _collectionKey: scenes,
      };

  KeyedScenesService.fromJson(JsonObj json) {
    for (var item in fromJsonList(json[_collectionKey], KeyedScene.fromJson)) {
      add(item);
    }
  }
}
