import 'package:flutter/material.dart';

import '../random_events/random_event.dart';
import '../roll_log/roll_lookup_view.dart';
import '../styles.dart';
import 'fate_chart.dart';

class FateChartLookupView extends StatelessWidget {
  final Probability probability;
  final FateChartOutcomeProbability outcomeProbability;

  const FateChartLookupView({
    required this.probability,
    required this.outcomeProbability,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RollLookupView(
      header: probability.text,
      rollColors: AppStyles.fateChartColors,
      entries: [
        if (outcomeProbability.extremeYes > 0)
          RollLookupEntry(
            value: '0 - ${outcomeProbability.extremeYes}',
            label: 'Extreme Yes',
          ),
        RollLookupEntry(
          value:
              '${outcomeProbability.extremeYes + 1} - ${outcomeProbability.threshold}',
          label: 'Yes',
        ),
        RollLookupEntry(
          value:
              '${outcomeProbability.threshold + 1} - ${outcomeProbability.extremeNo - 1}',
          label: 'No',
        ),
        if (outcomeProbability.extremeNo <= 100)
          RollLookupEntry(
            value: '${outcomeProbability.extremeNo} - 100',
            label: 'Extreme No',
          ),
      ],
      additionalContent: TextButton(
        onPressed: () {
          Navigator.pop(context);

          showRandomEventLookup(context);
        },
        child: const Text('ROLL RANDOM EVENT'),
      ),
    );
  }
}
