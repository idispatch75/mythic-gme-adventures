import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/dialogs.dart';
import '../../helpers/inline_link.dart';
import '../../storages/data_storage.dart';
import '../preferences/preferences.dart';
import '../styles.dart';
import '../widgets/actions_menu.dart';
import '../widgets/progress_indicators.dart';
import 'adventure.dart';
import 'adventure_info_controller.dart';

class AdventureInfoView extends GetView<AdventureInfoController> {
  final bool dense;

  const AdventureInfoView({this.dense = false, super.key});

  @override
  Widget build(BuildContext context) {
    final adventure = Get.find<AdventureService>();
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(
          () => Row(
            children: [
              // name
              Expanded(
                child: Text(
                  adventure.name(),
                  style: dense
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.headlineMedium,
                  overflow: dense ? TextOverflow.fade : TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

              // save error
              if (controller.hasError() && !controller.saving())
                IconButton(
                  onPressed: _showError,
                  icon: const Icon(Icons.save_outlined),
                  color: theme.colorScheme.error,
                ),

              // saving indicator
              if (controller.saving())
                const StackedProgressIndicator(
                  child: Icon(Icons.save_outlined),
                ),

              // actions button
              _AdventureActionsButton(withSaveDate: dense),
            ],
          ),
        ),

        // save date
        if (!dense)
          Obx(
            () {
              final saveDate = controller.saveDate();

              return saveDate != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(
                        saveDate,
                        style: theme.textTheme.labelSmall,
                        textAlign: TextAlign.right,
                      ),
                    )
                  : const SizedBox();
            },
          ),
      ],
    );
  }

  Future<void> _showError() async {
    String details;
    final error = controller.error;
    if (error is LocalStorageException) {
      details = 'Failed to save "${error.filePath}" locally: ${error.error}';
    } else if (error is RemoteStorageException) {
      details = 'Failed to save "${error.filePath}" online: ';
      if (error is RemoteStorageAuthenticationException) {
        details += 'The authentication is no more valid.\n'
            'Please go back to the list of adventures and check your online access.';
      } else if (error is RemoteStorageNetworkException) {
        details += '${error.provider} could not be contacted.\n'
            'Please check your internet access.';
      } else if (error is RemoteStorageOperationException) {
        details += '${error.provider} refused to save the file:'
            ' ${error.error}.';
      }
    } else {
      details = 'An unexpected error occurred: $error.';
    }

    await Dialogs.showAlert(
      title: 'Save failed',
      message: 'Failed to save the Adventure.\n\n$details',
    );
  }
}

class _AdventureActionsButton extends GetView<AdventureInfoController> {
  final bool withSaveDate;

  const _AdventureActionsButton({this.withSaveDate = false});

  @override
  Widget build(BuildContext context) {
    Widget actionButtons(String? saveDate) {
      final theme = Theme.of(context);

      return ActionsMenu([
        // save date
        if (saveDate != null)
          MenuItemButton(
            onPressed: null,
            style: TextButton.styleFrom(
              textStyle: theme.textTheme.labelMedium,
            ),
            child: Text(saveDate),
          ),

        // change adventure
        MenuItemButton(
          onPressed: () => controller.showIndex(context),
          leadingIcon: const Icon(Icons.arrow_back),
          child: const Text('Change Adventure'),
        ),

        // adventure settings
        MenuItemButton(
          onPressed: controller.showAdventureSettings,
          leadingIcon: const Icon(Icons.settings_outlined),
          child: const Text('Adventure Settings'),
        ),

        // global settings
        MenuItemButton(
          onPressed: controller.showGlobalSettings,
          leadingIcon: const Icon(Icons.settings_outlined),
          child: const Text('Global Settings'),
        ),

        // physical dice mode
        Obx(() {
          final isPhysicalDiceModeEnabled = getPhysicalDiceModeEnabled;

          return MenuItemButton(
            onPressed: controller.togglePhysicalDiceMode,
            leadingIcon: Stack(
              children: [
                AppStyles.rollIcon,
                if (isPhysicalDiceModeEnabled) const Icon(Icons.clear),
              ],
            ),
            child: Text(
              '${isPhysicalDiceModeEnabled ? 'Disable' : 'Enable'} Physical Dice Mode',
            ),
          );
        }),

        // Save
        MenuItemButton(
          onPressed: controller.save,
          leadingIcon: const Icon(Icons.save_outlined),
          child: const Text('Save'),
        ),

        // Export
        MenuItemButton(
          onPressed: controller.export,
          leadingIcon: const Icon(Icons.archive_outlined),
          child: const Text('Export'),
        ),

        // About
        MenuItemButton(
          onPressed: () async {
            final info = await PackageInfo.fromPlatform();

            if (context.mounted) {
              showAboutDialog(
                  applicationName: info.appName,
                  applicationVersion: info.version,
                  context: context,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text:
                                      'Manage adventures using the rules of Mythic Game Master Emulator, 2nd Edition.\n'
                                      'Find out more on the ',
                                ),
                                getInlineLink(
                                  text: 'official site',
                                  url:
                                      'https://idispatch75.github.io/mythic-gme-adventures/',
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              'This work is based on Mythic Game Master Emulator, 2nd Edition by Tana Pigeon,'
                              ' published by Word Mill Games, and licensed for our use under the Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license.'
                              ' Find out more at www.wordmillgames.com.\n'
                              'The App icon was created by Muhammad Miftakhul Rizky'
                              ' from thenounproject.com (CC BY 3.0).',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]);
            }
          },
          leadingIcon: const Icon(Icons.info_outline),
          child: const Text('About'),
        ),
      ]);
    }

    return withSaveDate
        ? Obx(() => actionButtons(controller.saveDate()))
        : actionButtons(null);
  }
}
