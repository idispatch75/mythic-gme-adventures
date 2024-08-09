import 'dart:math';

import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../characters/character.dart';
import '../global_settings/global_settings.dart';
import '../player_characters/player_character.dart';
import '../roll_log/roll_log.dart';
import '../threads/thread.dart';

sealed class RandomEventFocus {
  String get name;
  String? get target => null;

  RandomEventFocus();

  Map<String, dynamic> toJson() => {
        'runtimeType': runtimeType.toString(),
        'name': name,
        if (target != null) 'target': target,
      };

  factory RandomEventFocus.fromJson(Map<String, dynamic> json) =>
      switch (json['runtimeType']) {
        'RemoteEvent' => RemoteEvent(),
        'AmbiguousEvent' => AmbiguousEvent(),
        'NewNpc' => NewNpc(),
        'NpcEvent' => NpcEvent(eventName: json['name'], target: json['target']),
        'PcEvent' => PcEvent(eventName: json['name'], target: json['target']),
        'CurrentContext' => CurrentContext(),
        _ => CurrentContext(),
      };
}

class RemoteEvent extends RandomEventFocus {
  @override
  String get name => 'Remote Event';
}

class AmbiguousEvent extends RandomEventFocus {
  @override
  String get name => 'Ambiguous Event';
}

class NewNpc extends RandomEventFocus {
  @override
  String get name => 'New NPC';
}

class NpcEvent extends RandomEventFocus {
  final String _eventName;
  final String? _target;

  NpcEvent({required String eventName, required String target})
      : _eventName = eventName,
        _target = target;

  @override
  String get name => _eventName;

  @override
  String? get target => _target;
}

class ThreadEvent extends RandomEventFocus {
  final String _eventName;
  final String? _target;

  ThreadEvent({required String eventName, required String? target})
      : _eventName = eventName,
        _target = target;

  @override
  String get name => _eventName;

  @override
  String? get target => _target;
}

class PcEvent extends RandomEventFocus {
  final String _eventName;
  final String? _target;

  PcEvent({required String eventName, required String? target})
      : _eventName = eventName,
        _target = target;

  @override
  String get name => _eventName;

  @override
  String? get target => _target;
}

class CurrentContext extends RandomEventFocus {
  @override
  String get name => 'Current Context';
}

void rollRandomEvent() {
  final dieRoll = roll100Die();

  RandomEventFocus? focus;
  if (dieRoll <= 5) {
    focus = RemoteEvent();
  } else if (dieRoll <= 10) {
    focus = AmbiguousEvent();
  } else if (dieRoll <= 20) {
    focus = NewNpc();
  } else if (dieRoll <= 40) {
    final result = rollListItem(Get.find<CharactersService>().itemsList);
    if (result != null) {
      focus = NpcEvent(
          eventName: 'NPC Action',
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= 45) {
    final result = rollListItem(Get.find<CharactersService>().itemsList);
    if (result != null) {
      focus = NpcEvent(
          eventName: 'NPC Negative',
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= 50) {
    final result = rollListItem(Get.find<CharactersService>().itemsList);
    if (result != null) {
      focus = NpcEvent(
          eventName: 'NPC Positive',
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= 55) {
    final result = rollListItem(Get.find<ThreadsService>().itemsList);
    if (result != null) {
      focus = ThreadEvent(
          eventName: 'Move toward a Thread',
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= 65) {
    final result = rollListItem(Get.find<ThreadsService>().itemsList);
    if (result != null) {
      focus = ThreadEvent(
          eventName: 'Move away from a Thread',
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= 70) {
    final result = rollListItem(Get.find<ThreadsService>().itemsList);
    if (result != null) {
      focus = ThreadEvent(
          eventName: 'Close a Thread',
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= 80) {
    final result =
        rollListItem(Get.find<PlayerCharactersService>().playerCharacters);
    focus = result != null
        ? PcEvent(
            eventName: 'PC Positive',
            target: result.choose ? 'Choose' : result.item!.value.name)
        : PcEvent(eventName: 'PC Positive', target: '');
  } else if (dieRoll <= 85) {
    final result =
        rollListItem(Get.find<PlayerCharactersService>().playerCharacters);
    focus = result != null
        ? PcEvent(
            eventName: 'PC Negative',
            target: result.choose ? 'Choose' : result.item!.value.name)
        : PcEvent(eventName: 'PC Negative', target: '');
  }

  Get.find<RollLogService>()
      .addRandomEventRoll(focus: focus ?? CurrentContext(), dieRoll: dieRoll);
}

class ListRollResult<T> {
  final T? item;
  final bool choose;
  final int dieRoll;

  ListRollResult.choose(this.choose, this.dieRoll) : item = null;
  ListRollResult.item(this.item, this.dieRoll) : choose = false;
}

ListRollResult<T>? rollListItem<T>(List<T> list) {
  if (list.isNotEmpty) {
    final globalSettings = Get.find<GlobalSettingsService>();

    final nbSlots = globalSettings.allowChooseInLists
        ? list.length % 10 == 0
            ? list.length
            : (list.length ~/ 10 + 1) * 10
        : list.length;

    final index = Random().nextInt(nbSlots);
    if (index < list.length) {
      return ListRollResult.item(list[index], index + 1);
    } else {
      return ListRollResult.choose(true, index + 1);
    }
  }

  return null;
}
