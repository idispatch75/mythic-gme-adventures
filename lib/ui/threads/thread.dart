import 'package:get/get.dart';

import '../../helpers/get_extensions.dart';
import '../../helpers/json_utils.dart';
import '../listable_items/listable_item.dart';
import 'thread_ctl.dart';

class Thread extends ListableItem {
  final RxBool isTracked;
  final RxInt progress;
  final RxList<Rx<ThreadProgressPhase>> phases;

  Thread(
    super.id,
    super.name, {
    bool isTracked = false,
    int progress = 0,
    List<ThreadProgressPhase>? phases,
  }) : isTracked = isTracked.obs,
       progress = progress.obs,
       phases = (phases ?? []).map((e) => e.obs).toList().obs;

  @override
  JsonObj toJson() => super.toJson()
    ..addAll({
      'isTracked': isTracked(),
      'progress': progress(),
      'phases': phases,
    });

  Thread.fromJson(super.json)
    : isTracked = RxBool(json['isTracked']),
      progress = RxInt(json['progress']),
      phases = fromJsonList(
        json['phases'],
        (e) => ThreadProgressPhase.fromJson(e).obs,
      ).obs,
      super.fromJson();
}

class ThreadProgressPhase {
  bool hasFlashpoint;

  ThreadProgressPhase({this.hasFlashpoint = false});

  JsonObj toJson() => {
    'hasFlashpoint': hasFlashpoint,
  };

  ThreadProgressPhase.fromJson(JsonObj json)
    : this(hasFlashpoint: json['hasFlashpoint']);
}

class ThreadsService extends ListableItemsService<Thread> {
  ThreadsService();

  @override
  Rx<Thread> add(Thread item) {
    final thread = super.add(item);

    Get.replaceForced(ThreadController(item), tag: item.toTag());

    return thread;
  }

  JsonObj toJson() => toJsonGeneric('threads');

  ThreadsService.fromJson(JsonObj json)
    : super.fromJson(json, 'threads', Thread.fromJson);
}
