import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../helpers/utils.dart';
import '../adventure/adventure.dart';
import '../characters/character.dart';
import '../features/feature.dart';
import '../global_settings/global_settings.dart';
import '../listable_items/listable_item.dart';
import '../listable_items/listable_items_lookup_view.dart';
import '../player_characters/player_character.dart';
import '../roll_log/roll_log.dart';
import '../threads/thread.dart';
import 'random_event_lookup_view.dart';

sealed class RandomEventFocus {
  String get name;
  String? get target => null;

  RandomEventFocus();

  JsonObj toJson() => {
        'runtimeType': switch (this) {
          RemoteEvent() => RemoteEvent._id,
          AdventureFeature() => AdventureFeature._id,
          AmbiguousEvent() => AmbiguousEvent._id,
          NewNpc() => NewNpc._id,
          NpcEvent() => NpcEvent._id,
          ThreadEvent() => ThreadEvent._id,
          PcEvent() => PcEvent._id,
          CurrentContext() => CurrentContext._id,
        },
        'name': name,
        if (target != null) 'target': target,
      };

  factory RandomEventFocus.fromJson(JsonObj json) =>
      switch (json['runtimeType']) {
        RemoteEvent._id => RemoteEvent(),
        AdventureFeature._id => AdventureFeature(target: json['target']),
        AmbiguousEvent._id => AmbiguousEvent(),
        NewNpc._id => NewNpc(),
        NpcEvent._id =>
          NpcEvent(eventName: json['name'], target: json['target']),
        ThreadEvent._id =>
          ThreadEvent(eventName: json['name'], target: json['target']),
        PcEvent._id => PcEvent(eventName: json['name'], target: json['target']),
        CurrentContext._id => CurrentContext(),
        _ => CurrentContext(),
      };
}

class RemoteEvent extends RandomEventFocus {
  static const String _id = 'RemoteEvent';

  static const String eventName = 'Remote Event';
  static const int rollThreshold = 5;

  @override
  String get name => eventName;
}

class AmbiguousEvent extends RandomEventFocus {
  static const String _id = 'AmbiguousEvent';

  static const String eventName = 'Ambiguous Event';
  static const int rollThreshold = 10;

  @override
  String get name => eventName;
}

class NewNpc extends RandomEventFocus {
  static const String _id = 'NewNpc';

  static const String eventName = 'New NPC';
  static const int rollThreshold = 20;

  @override
  String get name => eventName;
}

class AdventureFeature extends RandomEventFocus {
  static const String _id = 'AdventureFeature';

  static const String eventName = 'Adventure Feature';
  static const int rollThreshold = 20;

  final String _target;

  AdventureFeature({required String target}) : _target = target;

  @override
  String get name => eventName;

  @override
  String? get target => _target;
}

class NpcEvent extends RandomEventFocus {
  static const String _id = 'NpcEvent';

  static const String actionEventName = 'NPC Action';
  static const String negativeEventName = 'NPC Negative';
  static const String positiveEventName = 'NPC Positive';
  static int actionRollThreshold({required bool isPreparedAdventure}) => 40;
  static int negativeRollThreshold({required bool isPreparedAdventure}) =>
      isPreparedAdventure ? 50 : 45;
  static int positiveRollThreshold({required bool isPreparedAdventure}) =>
      isPreparedAdventure ? 55 : 50;

  final String _eventName;
  final String _target;

  NpcEvent({required String eventName, required String target})
      : _eventName = eventName,
        _target = target;

  @override
  String get name => _eventName;

  @override
  String? get target => _target;
}

class ThreadEvent extends RandomEventFocus {
  static const String _id = 'ThreadEvent';

  static const String towardEventName = 'Move toward a Thread';
  static const String awayEventName = 'Move away from a Thread';
  static const String closeEventName = 'Close a Thread';
  static const int towardRollThreshold = 55;
  static const int awayRollThreshold = 65;
  static const int closeRollThreshold = 70;

  final String _eventName;
  final String _target;

  ThreadEvent({required String eventName, required String target})
      : _eventName = eventName,
        _target = target;

  @override
  String get name => _eventName;

  @override
  String? get target => _target;
}

class PcEvent extends RandomEventFocus {
  static const String _id = 'PcEvent';

  static const String negativeEventName = 'PC Negative';
  static const String positiveEventName = 'PC Positive';
  static int negativeRollThreshold({required bool isPreparedAdventure}) =>
      isPreparedAdventure ? 70 : 80;
  static int positiveRollThreshold({required bool isPreparedAdventure}) =>
      isPreparedAdventure ? 80 : 85;

  final String _eventName;
  final String _target;

  PcEvent({required String eventName, required String target})
      : _eventName = eventName,
        _target = target;

  @override
  String get name => _eventName;

  @override
  String? get target => _target;
}

class CurrentContext extends RandomEventFocus {
  static const String _id = 'CurrentContext';

  static const String eventName = 'Current Context';
  static const int rollThreshold = 100;

  @override
  String get name => eventName;
}

void rollRandomEvent() {
  final dieRoll = roll100Die();

  final isPreparedAdventure =
      Get.find<AdventureService>().isPreparedAdventure();

  RandomEventFocus? focus;
  if (dieRoll <= RemoteEvent.rollThreshold && !isPreparedAdventure) {
    focus = RemoteEvent();
  }
  //
  else if (dieRoll <= AdventureFeature.rollThreshold && isPreparedAdventure) {
    final result = rollListItem(Get.find<FeaturesService>()
        .features
        .where((e) => !e().isArchived)
        .toList());
    if (result != null) {
      focus = AdventureFeature(
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  }
  //
  else if (dieRoll <= AmbiguousEvent.rollThreshold && !isPreparedAdventure) {
    focus = AmbiguousEvent();
  }
  //
  else if (dieRoll <= NewNpc.rollThreshold && !isPreparedAdventure) {
    focus = NewNpc();
  }
  //
  else if (dieRoll <=
      NpcEvent.actionRollThreshold(isPreparedAdventure: isPreparedAdventure)) {
    final result = rollListItem(Get.find<CharactersService>().itemsList);
    if (result != null) {
      focus = NpcEvent(
          eventName: NpcEvent.actionEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  }
  //
  else if (dieRoll <=
      NpcEvent.negativeRollThreshold(
          isPreparedAdventure: isPreparedAdventure)) {
    final result = rollListItem(Get.find<CharactersService>().itemsList);
    if (result != null) {
      focus = NpcEvent(
          eventName: NpcEvent.negativeEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  }
  //
  else if (dieRoll <=
      NpcEvent.positiveRollThreshold(
          isPreparedAdventure: isPreparedAdventure)) {
    final result = rollListItem(Get.find<CharactersService>().itemsList);
    if (result != null) {
      focus = NpcEvent(
          eventName: NpcEvent.positiveEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  }
  //
  else if (dieRoll <= ThreadEvent.towardRollThreshold && !isPreparedAdventure) {
    final result = rollListItem(Get.find<ThreadsService>().itemsList);
    if (result != null) {
      focus = ThreadEvent(
          eventName: ThreadEvent.towardEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  }
  //
  else if (dieRoll <= ThreadEvent.awayRollThreshold && !isPreparedAdventure) {
    final result = rollListItem(Get.find<ThreadsService>().itemsList);
    if (result != null) {
      focus = ThreadEvent(
          eventName: ThreadEvent.awayEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  }
  //
  else if (dieRoll <= ThreadEvent.closeRollThreshold && !isPreparedAdventure) {
    final result = rollListItem(Get.find<ThreadsService>().itemsList);
    if (result != null) {
      focus = ThreadEvent(
          eventName: ThreadEvent.closeEventName,
          target: result.choose ? 'Choose' : result.item!.value.name);
    }
  }
  //
  else if (dieRoll <=
      PcEvent.negativeRollThreshold(isPreparedAdventure: isPreparedAdventure)) {
    final result =
        rollListItem(Get.find<PlayerCharactersService>().playerCharacters);
    focus = result != null
        ? PcEvent(
            eventName: PcEvent.negativeEventName,
            target: result.choose ? 'Choose' : result.item!.value.name)
        : PcEvent(eventName: PcEvent.negativeEventName, target: '');
  }
  //
  else if (dieRoll <=
      PcEvent.positiveRollThreshold(isPreparedAdventure: isPreparedAdventure)) {
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

  const ListRollResult.choose(this.choose, this.dieRoll) : item = null;
  const ListRollResult.item(this.item, this.dieRoll) : choose = false;
}

ListRollResult<T>? rollListItem<T>(List<T> sourceItems) {
  if (sourceItems.isNotEmpty) {
    final allowChooseInLists =
        Get.find<GlobalSettingsService>().allowChooseInLists;

    final nbSlots = allowChooseInLists
        ? sourceItems.length % 5 == 0
            ? sourceItems.length
            : (sourceItems.length ~/ 5 + 1) * 5
        : sourceItems.length;

    final index = Random().nextInt(nbSlots);
    if (index < sourceItems.length) {
      return ListRollResult.item(sourceItems[index], index + 1);
    } else {
      return ListRollResult.choose(true, index + 1);
    }
  }

  return null;
}

void showListItemsLookup<T extends ListableItem>(
    BuildContext context, String listLabel, List<T> sourceItems) {
  final itemNames = sourceItems
      .sorted((a, b) => a.name.compareTo(b.name))
      .map<String?>((e) => e.name)
      .toList();

  _showLookup(context, listLabel, itemNames);
}

void showPlayerCharactersLookup(BuildContext context) {
  final playerCharacters = Get.find<PlayerCharactersService>().playerCharacters;

  final itemNames = playerCharacters.map<String?>((e) => e.value.name).toList();

  _showLookup(context, 'Players', itemNames);
}

void showFeaturesLookup(BuildContext context) {
  final features = Get.find<FeaturesService>().features;

  final itemNames = features
      .where((e) => !e().isArchived)
      .map<String?>((e) => e.value.name)
      .toList();

  _showLookup(context, 'Features', itemNames);
}

void _showLookup(BuildContext context, String title, List<String?> itemNames) {
  if (itemNames.length % 5 != 0) {
    final missingItems = (itemNames.length ~/ 5 + 1) * 5 - itemNames.length;
    for (var i = 0; i < missingItems; i++) {
      itemNames.add(null);
    }
  }

  final content = ListableItemsLookupView(title, itemNames);

  showAppModalBottomSheet<void>(context, content);
}
