import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../characters/character.dart';
import '../global_settings/global_settings.dart';
import '../player_characters/player_character.dart';
import '../roll_log/roll_log.dart';
import '../threads/thread.dart';
import 'random_event_lookup_view.dart';

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
  static const String eventName = 'Remote Event';
  static const int rollThreshold = 5;

  @override
  String get name => eventName;
}

class AmbiguousEvent extends RandomEventFocus {
  static const String eventName = 'Ambiguous Event';
  static const int rollThreshold = 10;

  @override
  String get name => eventName;
}

class NewNpc extends RandomEventFocus {
  static const String eventName = 'New NPC';
  static const int rollThreshold = 20;

  @override
  String get name => eventName;
}

class NpcEvent extends RandomEventFocus {
  static const String actionEventName = 'NPC Action';
  static const String negativeEventName = 'NPC Negative';
  static const String positiveEventName = 'NPC Positive';
  static const int actionRollThreshold = 40;
  static const int negativeRollThreshold = 45;
  static const int positiveRollThreshold = 50;

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
  static const String towardEventName = 'Move toward a Thread';
  static const String awayEventName = 'Move away from a Thread';
  static const String closeEventName = 'Close a Thread';
  static const int towardRollThreshold = 55;
  static const int awayRollThreshold = 65;
  static const int closeRollThreshold = 70;

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
  static const String negativeEventName = 'PC Negative';
  static const String positiveEventName = 'PC Positive';
  static const int negativeRollThreshold = 80;
  static const int positiveRollThreshold = 85;

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
  static const String eventName = 'Current Context';
  static const int rollThreshold = 100;

  @override
  String get name => eventName;
}

void rollRandomEvent() {
  final dieRoll = roll100Die();

  RandomEventFocus? focus;
  if (dieRoll <= RemoteEvent.rollThreshold) {
    focus = RemoteEvent();
  } else if (dieRoll <= AmbiguousEvent.rollThreshold) {
    focus = AmbiguousEvent();
  } else if (dieRoll <= NewNpc.rollThreshold) {
    focus = NewNpc();
  } else if (dieRoll <= NpcEvent.actionRollThreshold) {
    final result = rollListItem(Get.find<CharactersService>().itemsList);
    if (result != null) {
      focus = NpcEvent(
          eventName: NpcEvent.actionEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= NpcEvent.negativeRollThreshold) {
    final result = rollListItem(Get.find<CharactersService>().itemsList);
    if (result != null) {
      focus = NpcEvent(
          eventName: NpcEvent.negativeEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= NpcEvent.positiveRollThreshold) {
    final result = rollListItem(Get.find<CharactersService>().itemsList);
    if (result != null) {
      focus = NpcEvent(
          eventName: NpcEvent.positiveEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= ThreadEvent.towardRollThreshold) {
    final result = rollListItem(Get.find<ThreadsService>().itemsList);
    if (result != null) {
      focus = ThreadEvent(
          eventName: ThreadEvent.towardEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= ThreadEvent.awayRollThreshold) {
    final result = rollListItem(Get.find<ThreadsService>().itemsList);
    if (result != null) {
      focus = ThreadEvent(
          eventName: ThreadEvent.awayEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= ThreadEvent.closeRollThreshold) {
    final result = rollListItem(Get.find<ThreadsService>().itemsList);
    if (result != null) {
      focus = ThreadEvent(
          eventName: ThreadEvent.closeEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  } else if (dieRoll <= PcEvent.negativeRollThreshold) {
    final result =
        rollListItem(Get.find<PlayerCharactersService>().playerCharacters);
    focus = result != null
        ? PcEvent(
            eventName: PcEvent.negativeEventName,
            target: result.choose ? 'Choose' : result.item!.value.name)
        : PcEvent(eventName: PcEvent.negativeEventName, target: '');
  } else if (dieRoll <= PcEvent.positiveRollThreshold) {
    final result =
        rollListItem(Get.find<PlayerCharactersService>().playerCharacters);
    focus = result != null
        ? PcEvent(
            eventName: PcEvent.positiveEventName,
            target: result.choose ? 'Choose' : result.item!.value.name)
        : PcEvent(eventName: PcEvent.positiveEventName, target: '');
  }

  Get.find<RollLogService>()
      .addRandomEventRoll(focus: focus ?? CurrentContext(), dieRoll: dieRoll);
}

void showRandomEventLookup(BuildContext context) {
  const content = RandomEventLookupView();

  showAppModalBottomSheet<void>(context, content);
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
