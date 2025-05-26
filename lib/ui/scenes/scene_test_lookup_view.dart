import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../adventure/adventure.dart';
import '../chaos_factor/chaos_factor.dart';
import '../random_events/random_event.dart';
import '../roll_log/roll_lookup_view.dart';
import '../styles.dart';
import 'scene_adjustment_lookup_view.dart';

class SceneTestLookupView extends StatelessWidget {
  const SceneTestLookupView({super.key});

  @override
  Widget build(BuildContext context) {
    final chaosFactor = Get.find<ChaosFactorService>().chaosFactor();
    final isPreparedAdventure = Get.find<AdventureService>()
        .isPreparedAdventure();

    final entries = <RollLookupEntry>[];
    if (isPreparedAdventure) {
      entries.add(
        RollLookupEntry(
          value: '1 - $chaosFactor',
          label: 'Random Event',
        ),
      );
    } else {
      for (var i = 0; i < chaosFactor; i++) {
        entries.add(
          RollLookupEntry(
            value: (i + 1).toString(),
            label: i.isEven ? 'Altered Scene' : 'Interrupt Scene',
          ),
        );
      }
    }

    entries.add(
      RollLookupEntry(
        value: chaosFactor == 9 ? '10' : '${chaosFactor + 1} - 10',
        label: 'Expected Scene',
      ),
    );

    return RollLookupView(
      header: 'Test Expected Scene - 1d10',
      rollColors: AppStyles.genericColors,
      entries: entries,
      additionalContent: Column(
        children: [
          // roll random event
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              showRandomEventLookup(context);
            },
            child: const Text('ROLL RANDOM EVENT'),
          ),

          // roll adjustment
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              const content = SceneAdjustmentLookupView();

              showAppModalBottomSheet<void>(context, content);
            },
            child: const Text('ROLL ADJUSTMENT'),
          ),
        ],
      ),
    );
  }
}
