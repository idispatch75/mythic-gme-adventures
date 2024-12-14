import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../persisters/persister.dart';
import '../ui/adventure_index/adventure_index.dart';
import 'datetime_extensions.dart';
import 'dialogs.dart';

export 'utils.io.dart' if (dart.library.html) 'utils.web.dart';

int roll100Die() => Random().nextInt(100) + 1;

int roll10Die() => Random().nextInt(10) + 1;

int rollDie(int nbFaces) => Random().nextInt(nbFaces) + 1;

/// Returns a new ID each time it is called.
int get newId =>
    DateTime.timestamp().millisecondsSinceEpoch -
    DateTime(2023, 10, 1).millisecondsSinceEpoch;

/// Shows a snackbar with the specified [text].
void showSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      duration: const Duration(seconds: 2),
    ),
  );
}

Future<T?> showAppModalBottomSheet<T>(BuildContext context, Widget content) {
  return showModalBottomSheet<T>(
    context: context,
    constraints: const BoxConstraints.tightFor(width: 300),
    builder: (context) {
      return Column(
        children: [
          // content
          Expanded(
            child: content,
          ),

          // dismiss
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss'),
              ),
            ),
          )
        ],
      );
    },
  );
}

/// Builds a [ListView] with a [Divider] as separator.
ListView defaultListView({
  required int itemCount,
  required NullableIndexedWidgetBuilder itemBuilder,
}) {
  return ListView.separated(
    itemCount: itemCount,
    itemBuilder: itemBuilder,
    separatorBuilder: (_, __) => const Divider(height: 0, thickness: 1),
  );
}

/// On mobile, wraps the [child] with a [PopScope]
/// to [showCloseAppConfirmation] when closing the App.
Widget protectClose({required Widget child}) {
  if (GetPlatform.isWeb || GetPlatform.isDesktop) {
    return child;
  }

  return PopScope(
    canPop: false,
    onPopInvokedWithResult: (bool didPop, _) async {
      if (didPop) {
        return;
      }

      if (await showCloseAppConfirmation()) {
        unawaited(SystemNavigator.pop());
      }
    },
    child: child,
  );
}

/// Asks confirmation when closing the App.
Future<bool> showCloseAppConfirmation() {
  var message = 'Any unsaved progress will be lost.';

  if (Get.isRegistered<AdventureIndexService>()) {
    final adventureIndex = Get.find<AdventureIndexService>();

    final saveTimestamp = adventureIndex.adventures.fold(
      0,
      (prev, adventure) => max(prev, adventure.saveTimestamp ?? 0),
    );

    if (saveTimestamp > 0) {
      final saveDate = DateTime.fromMillisecondsSinceEpoch(saveTimestamp);

      // indicate the last save date
      message = 'Data was last saved ${saveDate.elapsedFromNow()}.\n\n'
          '$message';
    }
  }

  return Dialogs.showConfirmation(
    title: 'Close the application?',
    message: message,
  );
}

Future<void> handleUnsupportedSchemaVersion(
    UnsupportedSchemaVersionException exception) async {
  final actionMessage =
      GetPlatform.isWeb ? 'please close this page.' : 'the App will be closed.';

  await Dialogs.showAlert(
    title: 'Unsupported data format',
    message:
        'This version of the App does not support the new data format of the file ${exception.fileName}.'
        '\nPlease update the App to the latest version.'
        '\n\nTo prevent data loss, $actionMessage',
  );

  if (!GetPlatform.isWeb) {
    exit(0);
  }
}
