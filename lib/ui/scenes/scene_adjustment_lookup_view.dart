import 'package:flutter/material.dart';

import '../roll_log/roll_lookup_view.dart';
import '../styles.dart';

class SceneAdjustmentLookupView extends StatelessWidget {
  const SceneAdjustmentLookupView({super.key});

  @override
  Widget build(BuildContext context) {
    return RollLookupView(
      header: 'Test Expected Scene - 1d10',
      rollColors: AppStyles.genericColors,
      entries: const [
        RollLookupEntry(value: '1', label: 'Remove a Character'),
        RollLookupEntry(value: '2', label: 'Add a Character'),
        RollLookupEntry(value: '3', label: 'Reduce/Remove an Activity'),
        RollLookupEntry(value: '4', label: 'Increase an Activity'),
        RollLookupEntry(value: '5', label: 'Remove an Object'),
        RollLookupEntry(value: '6', label: 'Add an Object'),
        RollLookupEntry(value: '7 - 10', label: 'Make 2 Adjustments'),
      ],
    );
  }
}
