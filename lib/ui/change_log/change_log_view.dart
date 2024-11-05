import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import 'change_log.dart';

class ChangeLogWrapper extends StatefulWidget {
  final Widget child;

  const ChangeLogWrapper({required this.child, super.key});

  @override
  State<ChangeLogWrapper> createState() => _ChangeLogWrapperState();
}

class _ChangeLogWrapperState extends State<ChangeLogWrapper> {
  bool _wasDisplayed = false;

  @override
  Widget build(BuildContext context) {
    if (!_wasDisplayed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final changeLog = Get.find<ChangeLogService>();
        final entries = changeLog.getEntries();
        if (entries.isNotEmpty) {
          Dialogs.showAlert(
              title: "What's new",
              message: entries.map((e) => '- $e').join('\n'));
        }

        changeLog.markRead();

        _wasDisplayed = true;
      });
    }

    return widget.child;
  }
}
