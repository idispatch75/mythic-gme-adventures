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
        final versions = changeLog.getVersions();

        if (versions.isNotEmpty) {
          Get.dialog<void>(
            AlertDialog(
              title: const Text("What's new"),
              content: ConstrainedBox(
                constraints: Dialogs.dialogBoxConstraints,
                child: SingleChildScrollView(
                  // dialog hack
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: versions.map(_Version.new).toList(),
                  ),
                ),
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

        changeLog.markRead();

        _wasDisplayed = true;
      });
    }

    return widget.child;
  }
}

class _Version extends StatelessWidget {
  final ChangeLogVersion _version;

  const _Version(this._version);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _version.version,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        ..._version.entries.map((e) => Text('- $e')),
        const SizedBox(height: 8),
      ],
    );
  }
}
