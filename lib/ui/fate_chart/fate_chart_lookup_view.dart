import 'package:flutter/material.dart';

import '../../helpers/utils.dart';
import '../random_events/random_event.dart';
import '../roll_log/roll_lookup_view.dart';
import '../styles.dart';
import '../threads/thread.dart';
import '../threads/thread_discovery_lookup_view.dart';
import 'fate_chart.dart';

class FateChartLookupView extends StatelessWidget {
  final Probability probability;
  final FateChartOutcomeProbability outcomeProbability;
  final Thread? thread;

  const FateChartLookupView({
    required this.probability,
    required this.outcomeProbability,
    this.thread,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Widget additionalContent;
    if (thread != null) {
      additionalContent = TextButton(
        onPressed: () {
          Navigator.pop(context);

          final content = ThreadDiscoveryLookupView(thread!);

          showAppModalBottomSheet<void>(context, content);
        },
        child: const Text('ROLL DISCOVERY'),
      );
    } else {
      additionalContent = TextButton(
        onPressed: () {
          Navigator.pop(context);

          showRandomEventLookup(context);
        },
        child: const Text('ROLL RANDOM EVENT'),
      );
    }

    return RollLookupView(
      header: probability.text,
      rollColors: AppStyles.fateChartColors,
      entries: [
        if (outcomeProbability.extremeYes > 0)
          RollLookupEntry(
            value: _getValueLabel(1, outcomeProbability.extremeYes),
            label: 'Exceptional Yes',
          ),
        RollLookupEntry(
          value: _getValueLabel(
              outcomeProbability.extremeYes + 1, outcomeProbability.threshold),
          label: 'Yes',
        ),
        RollLookupEntry(
          value: _getValueLabel(outcomeProbability.threshold + 1,
              outcomeProbability.extremeNo - 1),
          label: 'No',
        ),
        if (outcomeProbability.extremeNo <= 100)
          RollLookupEntry(
            value: _getValueLabel(outcomeProbability.extremeNo, 100),
            label: 'Exceptional No',
          ),
      ],
      additionalContent: additionalContent,
    );
  }

  String _getValueLabel(int low, int high) {
    return low == high ? low.toString() : '$low - $high';
  }
}
