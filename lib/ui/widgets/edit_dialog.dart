import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import '../layouts/layout.dart';
import 'responsive_dialog.dart';

class EditDialog<TResult> extends HookWidget {
  final bool canDelete;

  /// Return null to cancel saving.
  final Future<TResult?> Function() onSave;

  final Future<void> Function()? onDelete;

  /// The label for the type of item being edited.
  /// Used when deleting only.
  final String? itemTypeLabel;

  /// Changes on this value trigger a Save:
  /// if the form is valid, [onSave] is called
  /// and the dialog is closed returning `true`.
  ///
  /// **This is valid for web and desktop only**.
  final RxBool? saveTrigger;

  /// The body is expanded into a [SingleChildScrollView],
  /// so if the body contains a [Column] with an [Expanded],
  /// set `Column.mainAxisSize: MainAxisSize.min`,
  /// and replace [Expanded] with a [Flexible] having `fit: FlexFit.loose`.
  final Widget body;

  final _formKey = GlobalKey<FormState>();

  /// A dialog for editing values,
  /// with Save, Cancel and Delete buttons.
  ///
  /// Displays in full screen on phones,
  /// and with a reasonable size otherwise.
  EditDialog({
    super.key,
    required this.onSave,
    required this.canDelete,
    this.itemTypeLabel,
    this.onDelete,
    this.saveTrigger,
    required this.body,
  });

  /// Helper method to trigger a Save using the [saveTrigger]
  /// used when creating the dialog.
  static void triggerSave(RxBool? saveTrigger) {
    if (saveTrigger != null) {
      saveTrigger.toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    Future<void> save() async {
      if (_formKey.currentState?.validate() ?? false) {
        final result = await onSave();

        if (result != null) {
          Get.back(result: result);
        }
      }
    }

    useEffect(() {
      if (saveTrigger != null && (GetPlatform.isWeb || GetPlatform.isDesktop)) {
        final subscription = saveTrigger!.listen((_) {
          save();
        });
        return subscription.cancel;
      }

      return null;
    }, const []);

    final deleteColor = Theme.of(context).colorScheme.error;

    return ResponsiveDialog(
      childBuilder: (isFullscreen) => Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.only(
            top: isFullscreen ? 0.0 : 8.0,
          ),
          child: Column(
            children: [
              // body
              Expanded(child: SingleChildScrollView(child: body)),

              // buttons
              Row(
                mainAxisAlignment: canDelete
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                children: [
                  // Delete button
                  if (canDelete)
                    OutlinedButton(
                      onPressed: _delete,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: deleteColor),
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(color: deleteColor),
                      ),
                    ),

                  // OK/Cancel row
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      textDirection: dialogButtonDirection,
                      children: [
                        // Cancel button
                        TextButton(
                          onPressed: () => Get.back<void>(),
                          child: const Text('Cancel'),
                        ),

                        const SizedBox(width: 8.0),

                        // Save button
                        FilledButton(
                          onPressed: save,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    if (await Dialogs.showConfirmation(
      title: 'Delete $itemTypeLabel',
      message: 'Delete the $itemTypeLabel?',
    )) {
      await onDelete!();

      Get.back<void>();
    }
  }
}
