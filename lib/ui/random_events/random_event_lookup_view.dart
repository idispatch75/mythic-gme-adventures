import 'package:flutter/material.dart';

import '../roll_log/roll_lookup_view.dart';
import '../styles.dart';
import 'random_event.dart';

class RandomEventLookupView extends StatelessWidget {
  const RandomEventLookupView({super.key});

  @override
  Widget build(BuildContext context) {
    return RollLookupView(
      header: 'Random Event',
      rollColors: AppStyles.randomEventColors,
      entries: const [
        RollLookupEntry(
          value: '1 - ${RemoteEvent.rollThreshold}',
          label: RemoteEvent.eventName,
        ),
        RollLookupEntry(
          value:
              '${RemoteEvent.rollThreshold + 1} - ${AmbiguousEvent.rollThreshold}',
          label: AmbiguousEvent.eventName,
        ),
        RollLookupEntry(
          value:
              '${AmbiguousEvent.rollThreshold + 1} - ${NewNpc.rollThreshold}',
          label: NewNpc.eventName,
        ),
        RollLookupEntry(
          value:
              '${NewNpc.rollThreshold + 1} - ${NpcEvent.actionRollThreshold}',
          label: NpcEvent.actionEventName,
        ),
        RollLookupEntry(
          value:
              '${NpcEvent.actionRollThreshold + 1} - ${NpcEvent.negativeRollThreshold}',
          label: NpcEvent.negativeEventName,
        ),
        RollLookupEntry(
          value:
              '${NpcEvent.negativeRollThreshold + 1} - ${NpcEvent.positiveRollThreshold}',
          label: NpcEvent.positiveEventName,
        ),
        RollLookupEntry(
          value:
              '${NpcEvent.positiveRollThreshold + 1} - ${ThreadEvent.towardRollThreshold}',
          label: ThreadEvent.towardEventName,
        ),
        RollLookupEntry(
          value:
              '${ThreadEvent.towardRollThreshold + 1} - ${ThreadEvent.awayRollThreshold}',
          label: ThreadEvent.awayEventName,
        ),
        RollLookupEntry(
          value:
              '${ThreadEvent.awayRollThreshold + 1} - ${ThreadEvent.closeRollThreshold}',
          label: ThreadEvent.closeEventName,
        ),
        RollLookupEntry(
          value:
              '${ThreadEvent.closeRollThreshold + 1} - ${PcEvent.negativeRollThreshold}',
          label: PcEvent.negativeEventName,
        ),
        RollLookupEntry(
          value:
              '${PcEvent.negativeRollThreshold + 1} - ${PcEvent.positiveRollThreshold}',
          label: PcEvent.positiveEventName,
        ),
        RollLookupEntry(
          value:
              '${PcEvent.positiveRollThreshold + 1} - ${CurrentContext.rollThreshold}',
          label: CurrentContext.eventName,
        ),
      ],
    );
  }
}
