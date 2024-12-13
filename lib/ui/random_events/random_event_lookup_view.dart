import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../adventure/adventure.dart';
import '../characters/character.dart';
import '../characters/characters_list.dart';
import '../features/feature.dart';
import '../player_characters/player_character.dart';
import '../roll_log/roll_lookup_view.dart';
import '../styles.dart';
import '../threads/thread.dart';
import '../threads/threads_list.dart';
import 'random_event.dart';

class RandomEventLookupView extends StatelessWidget {
  const RandomEventLookupView({super.key});

  @override
  Widget build(BuildContext context) {
    final characters = Get.find<CharactersListController>();
    final lookupCharacters = characters.items.isNotEmpty
        ? () => _showCharactersLookup(context, characters)
        : null;

    final threads = Get.find<ThreadsListController>();
    final lookupThreads = Get.find<ThreadsListController>().items.isNotEmpty
        ? () => _showThreadsLookup(context, threads)
        : null;

    final lookupPlayerCharacters =
        Get.find<PlayerCharactersService>().playerCharacters.length > 1
            ? () => _showPlayerCharactersLookup(context)
            : null;

    final lookupFeatures = Get.find<FeaturesService>().features.isNotEmpty
        ? () => _showFeaturesLookup(context)
        : null;

    final isPreparedAdventure =
        Get.find<AdventureService>().isPreparedAdventure();

    return RollLookupView(
      header: 'Random Event',
      rollColors: AppStyles.randomEventColors,
      entries: [
        // RemoteEvent
        if (!isPreparedAdventure)
          const RollLookupEntry(
            value: '1 - ${RemoteEvent.rollThreshold}',
            label: RemoteEvent.eventName,
          ),

        // Adventure Feature
        if (isPreparedAdventure)
          RollLookupEntry(
            value: '1 - ${AdventureFeature.rollThreshold}',
            label: AdventureFeature.eventName,
            onRoll: lookupFeatures,
          ),

        // Ambiguous Event
        if (!isPreparedAdventure)
          const RollLookupEntry(
            value:
                '${RemoteEvent.rollThreshold + 1} - ${AmbiguousEvent.rollThreshold}',
            label: AmbiguousEvent.eventName,
          ),

        // New NPC
        if (!isPreparedAdventure)
          const RollLookupEntry(
            value:
                '${AmbiguousEvent.rollThreshold + 1} - ${NewNpc.rollThreshold}',
            label: NewNpc.eventName,
          ),

        // NPC Action
        RollLookupEntry(
          value:
              '${(isPreparedAdventure ? AdventureFeature.rollThreshold : NewNpc.rollThreshold) + 1}'
              ' - ${NpcEvent.actionRollThreshold(isPreparedAdventure: isPreparedAdventure)}',
          label: NpcEvent.actionEventName,
          onRoll: lookupCharacters,
        ),

        // NPC Negative
        RollLookupEntry(
          value:
              '${NpcEvent.actionRollThreshold(isPreparedAdventure: isPreparedAdventure) + 1}'
              ' - ${NpcEvent.negativeRollThreshold(isPreparedAdventure: isPreparedAdventure)}',
          label: NpcEvent.negativeEventName,
          onRoll: lookupCharacters,
        ),

        // NPC Positive
        RollLookupEntry(
          value:
              '${NpcEvent.negativeRollThreshold(isPreparedAdventure: isPreparedAdventure) + 1}'
              ' - ${NpcEvent.positiveRollThreshold(isPreparedAdventure: isPreparedAdventure)}',
          label: NpcEvent.positiveEventName,
          onRoll: lookupCharacters,
        ),

        // Thread toward
        if (!isPreparedAdventure)
          RollLookupEntry(
            value:
                '${NpcEvent.positiveRollThreshold(isPreparedAdventure: isPreparedAdventure) + 1}'
                ' - ${ThreadEvent.towardRollThreshold}',
            label: ThreadEvent.towardEventName,
            onRoll: lookupThreads,
          ),

        // Thread away
        if (!isPreparedAdventure)
          RollLookupEntry(
            value:
                '${ThreadEvent.towardRollThreshold + 1} - ${ThreadEvent.awayRollThreshold}',
            label: ThreadEvent.awayEventName,
            onRoll: lookupThreads,
          ),

        // Thread close
        if (!isPreparedAdventure)
          RollLookupEntry(
            value:
                '${ThreadEvent.awayRollThreshold + 1} - ${ThreadEvent.closeRollThreshold}',
            label: ThreadEvent.closeEventName,
            onRoll: lookupThreads,
          ),

        // PC Negative
        RollLookupEntry(
          value:
              '${(isPreparedAdventure ? NpcEvent.positiveRollThreshold(isPreparedAdventure: isPreparedAdventure) : ThreadEvent.closeRollThreshold) + 1}'
              ' - ${PcEvent.negativeRollThreshold(isPreparedAdventure: isPreparedAdventure)}',
          label: PcEvent.negativeEventName,
          onRoll: lookupPlayerCharacters,
        ),

        // PC Positive
        RollLookupEntry(
          value:
              '${PcEvent.negativeRollThreshold(isPreparedAdventure: isPreparedAdventure) + 1} - ${PcEvent.positiveRollThreshold(isPreparedAdventure: isPreparedAdventure)}',
          label: PcEvent.positiveEventName,
          onRoll: lookupPlayerCharacters,
        ),

        // CurrentContext
        RollLookupEntry(
          value:
              '${PcEvent.positiveRollThreshold(isPreparedAdventure: isPreparedAdventure) + 1} - ${CurrentContext.rollThreshold}',
          label: CurrentContext.eventName,
        ),
      ],
    );
  }

  void _showCharactersLookup(
      BuildContext context, CharactersListController controller) {
    showListItemsLookup<Character>(
        context,
        CharactersListView.listItemTypeLabel,
        controller.sourceItemsList.map((e) => e.value).toList());
  }

  void _showThreadsLookup(
      BuildContext context, ThreadsListController controller) {
    showListItemsLookup<Thread>(context, ThreadsListView.listItemTypeLabel,
        controller.sourceItemsList.map((e) => e.value).toList());
  }

  void _showPlayerCharactersLookup(BuildContext context) {
    showPlayerCharactersLookup(context);
  }

  void _showFeaturesLookup(BuildContext context) {
    showFeaturesLookup(context);
  }
}
