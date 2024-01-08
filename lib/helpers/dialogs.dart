import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../ui/layouts/layout.dart';

Future<bool> showConfirmationDialog({
  required String title,
  String? message,
  Widget? child,
  String? okText,
  String? cancelText,
}) async {
  assert(
    message != null || child != null,
    'message add child cannot both be null',
  );

  if (message != null) {
    child = Text(message);
  }

  final okButton = FilledButton(
    onPressed: () {
      Get.back(result: true);
    },
    child: Text(okText ?? 'OK'),
  );

  final cancelButton = TextButton(
    onPressed: () {
      Get.back(result: false);
    },
    child: Text(cancelText ?? 'Cancel'),
  );

  var actions = [cancelButton, okButton];
  if (dialogButtonDirection == TextDirection.rtl) {
    actions = actions.reversed.toList();
  }

  return await Get.dialog<bool>(
        AlertDialog.adaptive(
          title: Text(title),
          content: ConstrainedBox(
            constraints: _dialogBoxConstraints,
            child: child,
          ),
          actions: actions,
        ),
        barrierDismissible: false,
      ) ??
      false;
}

Future<void> showAlertDialog({
  required String title,
  required String message,
}) {
  return Get.dialog<void>(
    AlertDialog.adaptive(
      title: Text(title),
      content: ConstrainedBox(
        constraints: _dialogBoxConstraints,
        child: Text(message),
      ),
      actions: [
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Get.back();
          },
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

Future<int?> showNumberPickerDialog({
  required String title,
}) {
  final numberController = TextEditingController();

  void save() {
    Get.back(result: int.tryParse(numberController.text));
  }

  final okButton = FilledButton(
    onPressed: save,
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

  return Get.dialog<int?>(
    AlertDialog.adaptive(
      title: Text(title),
      content: ConstrainedBox(
        constraints: _dialogBoxConstraints,
        child: TextField(
          controller: numberController,
          autofocus: true,
          keyboardType: TextInputType.number,
          onSubmitted: (_) => save(),
        ),
      ),
      actions: actions,
    ),
    barrierDismissible: false,
  );
}

const _dialogBoxConstraints = BoxConstraints(maxWidth: 500);
