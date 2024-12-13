import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/input_validators.dart';
import '../../helpers/string_extensions.dart';
import '../widgets/boolean_setting.dart';
import '../widgets/edit_dialog.dart';
import 'listable_item.dart';

abstract class ListableItemEditView<TItem extends ListableItem>
    extends HookWidget {
  final ListableItemsService<TItem> _controller;
  final TItem item;
  final String _itemTypeLabel;
  final bool canDelete;

  const ListableItemEditView(
    this._controller,
    this.item,
    this._itemTypeLabel, {
    required this.canDelete,
    super.key,
  });

  Widget? getComplement({
    required TextEditingController notesController,
  }) =>
      null;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: item.name);
    final summaryController = useTextEditingController(text: item.summary);
    final notesController = useTextEditingController(text: item.notes);

    final isArchived = item.isArchived.obs;

    final saveTrigger = false.obs;

    final complement = getComplement(notesController: notesController);

    return EditDialog<bool>(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            validator: validateNotEmpty,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: item.name.isEmpty,
            textCapitalization: TextCapitalization.sentences,
            onFieldSubmitted: (_) => EditDialog.triggerSave(saveTrigger),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: summaryController,
            decoration: const InputDecoration(labelText: 'Summary'),
            textCapitalization: TextCapitalization.sentences,
            onFieldSubmitted: (_) => EditDialog.triggerSave(saveTrigger),
          ),
          const SizedBox(height: 16),

          Flexible(
            fit: FlexFit.loose,
            child: TextFormField(
              controller: notesController,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),

          // complement
          if (complement != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: complement,
            ),

          // archive
          if (canDelete)
            BooleanSetting(
              setting: isArchived,
              text: 'Archived',
              subtext:
                  'Archiving a $_itemTypeLabel removes it from the ${_itemTypeLabel}s List'
                  ' and moves it at the end of the list of ${_itemTypeLabel}s.',
              hasTopPadding: true,
            ),
        ],
      ),
      itemTypeLabel: _itemTypeLabel,
      canDelete: canDelete,
      saveTrigger: saveTrigger,
      onSave: () {
        item.name = nameController.text;
        item.summary = summaryController.text.nullIfEmpty();
        item.notes = notesController.text.nullIfEmpty();
        _controller.archive(item, isArchived());

        _controller.requestSave();

        return Future.value(true);
      },
      onDelete: () {
        _controller.delete(item);
        return Future.value();
      },
    );
  }
}
