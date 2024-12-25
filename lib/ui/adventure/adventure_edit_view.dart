import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/input_validators.dart';
import '../fate_chart/fate_chart.dart';
import '../widgets/boolean_setting.dart';
import '../widgets/edit_dialog.dart';
import 'adventure.dart';

class AdventureEditView extends HookWidget {
  static final _fateChartTypeEntries = [
    const DropdownMenuEntry(value: FateChartType.standard, label: 'Standard'),
    const DropdownMenuEntry(value: FateChartType.mid, label: 'Mid'),
    const DropdownMenuEntry(value: FateChartType.low, label: 'Low'),
    const DropdownMenuEntry(value: FateChartType.none, label: 'None'),
  ];

  final AdventureService _adventure;

  const AdventureEditView(this._adventure, {super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: _adventure.name());
    final chartType = _adventure.fateChartType.obs;
    final isPreparedAdventure = _adventure.isPreparedAdventure().obs;

    final saveTrigger = false.obs;

    return EditDialog<bool>(
      itemTypeLabel: 'Adventure',
      canDelete: false,
      onSave: () {
        _adventure.name(nameController.text);
        _adventure.fateChartType = chartType();
        _adventure.isPreparedAdventure(isPreparedAdventure());

        return Future.value(true);
      },
      saveTrigger: saveTrigger,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: nameController,
            validator: validateNotEmpty,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: _adventure.name().isEmpty,
            textCapitalization: TextCapitalization.sentences,
            onFieldSubmitted: (_) => EditDialog.triggerSave(saveTrigger),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: DropdownMenu<FateChartType>(
                requestFocusOnTap: false,
                initialSelection: chartType(),
                label: const Text('Fate Chart'),
                dropdownMenuEntries: _fateChartTypeEntries,
                onSelected: (value) {
                  chartType.value = value ?? FateChartType.standard;
                },
              ),
            ),
          ),
          BooleanSetting(
            setting: isPreparedAdventure,
            text: 'Prepared Adventure',
            subtext: 'If checked, the Features list appears in the More tab,'
                ' Random Events use the Event Focus table of Prepared Adventures,'
                ' and altered/interrupt scenes are replaced with a Random Event.',
            withTopPadding: true,
          ),
        ],
      ),
    );
  }
}
