import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import '../../helpers/string_extensions.dart';
import '../global_settings/global_settings.dart';
import '../listable_items/listable_item_edit_view.dart';
import '../meaning_tables/meaning_table.dart';
import '../meaning_tables/meaning_tables_ctl.dart';
import '../widgets/rich_text_editor.dart';
import 'character.dart';

class CharacterEditView extends ListableItemEditView<Character> {
  const CharacterEditView(
    super._controller,
    super.item,
    super._itemTypeLabel, {
    required super.canDelete,
    super.key,
  });

  @override
  Widget? getComplement({
    required RichTextEditorController notesController,
  }) => _CharacterComplementEditView(notesController);
}

class _CharacterComplementEditView extends StatelessWidget {
  final RichTextEditorController _notesController;

  const _CharacterComplementEditView(
    this._notesController,
  );

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: OutlinedButton(
        onPressed: rollTraits,
        child: const Text('Roll traits'),
      ),
    );
  }

  Future<void> rollTraits() async {
    final selectedTables = <MeaningTable>{};

    if (await Dialogs.showValuePicker<bool>(
          title: 'Select Meaning Tables',
          child: _TablesPicker(selectedTables),
          onSave: () => Get.back(result: true),
        ) ??
        false) {
      // store selected tables
      final globalSettings = Get.find<GlobalSettingsService>();
      globalSettings.setCharacterTraitMeaningTables(
        selectedTables.map((e) => e.id).toList(),
      );

      // append rolls
      final tablesService = Get.find<MeaningTablesService>();
      final tablesController = Get.find<MeaningTablesController>();
      var traits = selectedTables
          .map((table) {
            var trait = '';
            if (table.characterTrait!.isNotEmpty) {
              trait = '${table.characterTrait}: ';
            }

            final rolls = tablesController.roll(table.id, addToLog: false);
            return trait +
                rolls
                    .map(
                      (e) => tablesService.getMeaningTableEntry(
                        e.entryId,
                        e.dieRoll,
                      ),
                    )
                    .join(', ');
          })
          .join('\n');

      final plainText = _notesController.quill.document.toPlainText();
      if (!plainText.endsWith('\n\n') && plainText.isNotEmpty) {
        traits = '\n$traits';
      }

      _notesController.quill.document.insert(
        max(0, plainText.length - 1),
        traits,
      );
    }
  }
}

class _TablesPicker extends StatefulWidget {
  final Set<MeaningTable> _selectedTables;

  const _TablesPicker(this._selectedTables);

  @override
  State<_TablesPicker> createState() => _TablesPickerState();
}

class _TablesPickerState extends State<_TablesPicker> {
  final List<MeaningTable> _characterTraitTables;

  _TablesPickerState()
    : _characterTraitTables = Get.find<MeaningTablesService>().meaningTables
          .where((e) => e.characterTrait != null)
          .sorted((a, b) {
            final orderA = a.order ?? 1000;
            final orderB = b.order ?? 1000;

            if (orderA == orderB) {
              return a.name.compareUsingLocale(b.name);
            } else {
              return orderA - orderB;
            }
          });

  @override
  void initState() {
    super.initState();

    final globalSettings = Get.find<GlobalSettingsService>();
    final previousSelectedTables = globalSettings.characterTraitMeaningTables;
    widget._selectedTables.addAll(
      _characterTraitTables.where((e) => previousSelectedTables.contains(e.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 450),
      child: SizedBox(
        // https://stackoverflow.com/questions/60891838/flutter-listview-with-radio-not-showing-in-alertdialog
        width: double.maxFinite,
        child: ListView.builder(
          itemCount: _characterTraitTables.length,
          itemBuilder: (_, index) {
            final table = _characterTraitTables[index];

            return CheckboxListTile(
              title: Text(
                table.characterTrait!.isEmpty
                    ? table.name
                    : table.characterTrait!,
              ),
              value: widget._selectedTables.contains(table),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    widget._selectedTables.add(table);
                  } else {
                    widget._selectedTables.remove(table);
                  }
                });
              },
            );
          },
        ),
      ),
    );
  }
}
