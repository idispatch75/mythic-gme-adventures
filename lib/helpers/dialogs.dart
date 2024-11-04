import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ui/layouts/layout.dart';
import 'inline_link.dart';

abstract class Dialogs {
  static const dialogBoxConstraints = BoxConstraints(maxWidth: 500);

  static Future<bool> showConfirmation({
    required String title,
    String? message,
    Widget? child,
    bool withUserManual = false,
  }) async {
    assert(
      message != null || child != null,
      'message add child cannot both be null',
    );

    if (message != null) {
      child = Text(message);
    }

    if (withUserManual) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          child!,
          SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'See the '),
                getUserManualLink(),
                TextSpan(text: ' for more info.'),
              ],
            ),
          )
        ],
      );
    }

    return await showValuePicker<bool>(
          title: title,
          child: child!,
          onSave: () => Get.back(result: true),
        ) ??
        false;
  }

  static Future<void> showAlert({
    required String title,
    required String message,
  }) {
    return Get.dialog<void>(
      AlertDialog.adaptive(
        title: Text(title),
        content: ConstrainedBox(
          constraints: dialogBoxConstraints,
          child: Text(message),
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Get.back<void>(),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  static Future<int?> showNumberPicker({
    required String title,
  }) {
    final numberController = TextEditingController();

    void save() {
      Get.back(result: int.tryParse(numberController.text));
    }

    return showValuePicker(
      title: title,
      child: TextField(
        controller: numberController,
        autofocus: true,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => save(),
      ),
      onSave: save,
    );
  }

  static Future<TValue?> showValuePicker<TValue>({
    required String title,
    required Widget child,
    required void Function() onSave,
  }) {
    final okButton = FilledButton(
      onPressed: onSave,
      child: const Text('OK'),
    );

    final cancelButton = TextButton(
      onPressed: () {
        Get.back(result: null);
      },
      child: const Text('Cancel'),
    );

    var actions = [cancelButton, okButton];
    if (dialogButtonDirection == TextDirection.rtl) {
      actions = actions.reversed.toList();
    }

    return Get.dialog<TValue?>(
      AlertDialog.adaptive(
        title: Text(title),
        content: ConstrainedBox(
          constraints: dialogBoxConstraints,
          child: child,
        ),
        actions: actions,
      ),
      barrierDismissible: false,
    );
  }
}
