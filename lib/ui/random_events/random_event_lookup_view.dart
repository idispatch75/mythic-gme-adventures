import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../characters/character.dart';
import '../characters/characters_list.dart';
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
    final lookupThreads = threads.items.isNotEmpty
        ? () => _showThreadsLookup(context, threads)
        : null;

    final lookupPlayerCharacters =
        Get.find<PlayerCharactersService>().playerCharacters.length > 1
            ? () => _showPlayerCharactersLookup(context)
            : null;

    return RollLookupView(
      header: 'Random Event',
      rollColors: AppStyles.randomEventColors,
      entries: [
        const RollLookupEntry(
          value: '1 - ${RemoteEvent.rollThreshold}',
          label: RemoteEvent.eventName,
        ),
        const RollLookupEntry(
          value:
              '${RemoteEvent.rollThreshold + 1} - ${AmbiguousEvent.rollThreshold}',
          label: AmbiguousEvent.eventName,
        ),
        const RollLookupEntry(
          value:
              '${AmbiguousEvent.rollThreshold + 1} - ${NewNpc.rollThreshold}',
          label: NewNpc.eventName,
        ),
        RollLookupEntry(
          value:
              '${NewNpc.rollThreshold + 1} - ${NpcEvent.actionRollThreshold}',
          label: NpcEvent.actionEventName,
          onRoll: lookupCharacters,
        ),
        RollLookupEntry(
          value:
              '${NpcEvent.actionRollThreshold + 1} - ${NpcEvent.negativeRollThreshold}',
          label: NpcEvent.negativeEventName,
          onRoll: lookupCharacters,
        ),
        RollLookupEntry(
          value:
              '${NpcEvent.negativeRollThreshold + 1} - ${NpcEvent.positiveRollThreshold}',
          label: NpcEvent.positiveEventName,
          onRoll: lookupCharacters,
        ),
        RollLookupEntry(
          value:
              '${NpcEvent.positiveRollThreshold + 1} - ${ThreadEvent.towardRollThreshold}',
          label: ThreadEvent.towardEventName,
          onRoll: lookupThreads,
        ),
        RollLookupEntry(
          value:
              '${ThreadEvent.towardRollThreshold + 1} - ${ThreadEvent.awayRollThreshold}',
          label: ThreadEvent.awayEventName,
          onRoll: lookupThreads,
        ),
        RollLookupEntry(
          value:
              '${ThreadEvent.awayRollThreshold + 1} - ${ThreadEvent.closeRollThreshold}',
          label: ThreadEvent.closeEventName,
          onRoll: lookupThreads,
        ),
        RollLookupEntry(
          value:
              '${ThreadEvent.closeRollThreshold + 1} - ${PcEvent.negativeRollThreshold}',
          label: PcEvent.negativeEventName,
          onRoll: lookupPlayerCharacters,
        ),
        RollLookupEntry(
          value:
              '${PcEvent.negativeRollThreshold + 1} - ${PcEvent.positiveRollThreshold}',
          label: PcEvent.positiveEventName,
          onRoll: lookupPlayerCharacters,
        ),
        const RollLookupEntry(
          value:
              '${PcEvent.positiveRollThreshold + 1} - ${CurrentContext.rollThreshold}',
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
}
