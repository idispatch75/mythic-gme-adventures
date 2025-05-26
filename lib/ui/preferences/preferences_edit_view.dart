import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';
import 'package:io/io.dart';

import '../../helpers/inline_link.dart';
import '../../helpers/string_extensions.dart';
import '../../storages/local_storage.dart';
import '../layouts/layout.dart';
import '../styles.dart';
import '../widgets/boolean_setting.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/sub_label.dart';
import 'preferences.dart';

class PreferencesEditView extends HookWidget {
  const PreferencesEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = Get.find<LocalPreferencesService>();

    final enableDarkMode = preferences.enableDarkMode().obs;

    final hasLocalFolder = !GetPlatform.isWeb;
    final TextEditingController localDataDirectoryController;
    final AsyncSnapshot<String> defaultLocalDataDirectory;
    final Future<PreferencesEditResult?> Function() onSave;

    void saveBrightness() {
      AppStyles.setBrightness(
        enableDarkMode() ? Brightness.dark : Brightness.light,
      );
      preferences.enableDarkMode.value = enableDarkMode();
    }

    if (hasLocalFolder) {
      localDataDirectoryController = useTextEditingController(
        text: preferences.localDataDirectoryOverride(),
      );

      final defaultLocalDataDirectoryFuture = useMemoized(
        () => LocalStorage.getDefaultRootDirectoryPath(),
      );
      defaultLocalDataDirectory = useFuture(defaultLocalDataDirectoryFuture);

      onSave = () async {
        // copy the files to the new directory?
        final currentDataDirectory = preferences.localDataDirectoryOverride();
        final newDataDirectory = localDataDirectoryController.text
            .nullIfEmpty();

        if (currentDataDirectory != newDataDirectory) {
          final doCopy = await _showConfirmationDialog(context);
          if (doCopy == null) {
            return null;
          }

          if (doCopy) {
            await copyPath(
              currentDataDirectory ?? defaultLocalDataDirectory.data!,
              newDataDirectory ?? defaultLocalDataDirectory.data!,
            );
          }
        }

        // save the settings
        preferences.localDataDirectoryOverride.value = newDataDirectory;

        saveBrightness();

        return PreferencesEditResult(currentDataDirectory != newDataDirectory);
      };
    } else {
      localDataDirectoryController = useTextEditingController();
      defaultLocalDataDirectory = const AsyncSnapshot<String>.waiting();

      onSave = () async {
        saveBrightness();

        return PreferencesEditResult(false);
      };
    }

    final theme = Theme.of(context);

    return EditDialog<PreferencesEditResult>(
      itemTypeLabel: 'Preferences',
      canDelete: false,
      onSave: onSave,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLocalFolder) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // data folder
                Expanded(
                  child: TextFormField(
                    controller: localDataDirectoryController,
                    decoration: const InputDecoration(
                      labelText: 'Local data folder',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    readOnly: true,
                  ),
                ),

                // choose folder
                IconButton(
                  onPressed: () async {
                    final initialDirectory =
                        localDataDirectoryController.text.nullIfEmpty() ??
                        defaultLocalDataDirectory.data;
                    final path = await FilePicker.platform.getDirectoryPath(
                      dialogTitle: 'Local data folder',
                      initialDirectory: initialDirectory,
                      lockParentWindow: true,
                    );

                    if (path != null) {
                      localDataDirectoryController.text = path;
                    }
                  },
                  icon: const Icon(Icons.folder),
                ),

                // clear folder
                IconButton(
                  onPressed: () {
                    localDataDirectoryController.text = '';
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),

            // tip
            const SizedBox(height: 4),
            SubLabel(
              'Leave blank to use the default folder "${defaultLocalDataDirectory.data}".',
            ),
            if (!GetPlatform.isWeb && GetPlatform.isDesktop)
              const SubLabel(
                'Consider setting your local Google Drive, OneDrive or Dropbox folder,'
                ' for easy sharing, fast save, and automatic backup with versioning.\n'
                'Setting the local Google Drive here while using Google Drive as online storage'
                ' must be avoided because the files uploaded by the Drive App will not be visible by this App.',
              ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'More info in the ',
                    style: SubLabel.getTextStyle(theme),
                  ),
                  getUserManualLink(
                    anchor: 'storage',
                    textStyle: SubLabel.getTextStyle(theme),
                  ),
                  TextSpan(
                    text: '.',
                    style: SubLabel.getTextStyle(theme),
                  ),
                ],
              ),
            ),
          ],

          // brightness
          BooleanSetting(
            setting: enableDarkMode,
            text: 'Dark mode',
            withTopPadding: true,
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context) async {
    final noCopyButton = TextButton(
      child: const Text('Do not copy'),
      onPressed: () {
        Get.back(result: false);
      },
    );

    final copyButton = TextButton(
      child: Text(
        'Copy',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      onPressed: () {
        Get.back(result: true);
      },
    );

    final cancelButton = TextButton(
      child: const Text('Cancel'),
      onPressed: () {
        Get.back(result: null);
      },
    );

    var actions = [cancelButton, copyButton, noCopyButton];
    if (dialogButtonDirection == TextDirection.rtl) {
      actions = actions.reversed.toList();
    }

    return Get.dialog<bool>(
      AlertDialog.adaptive(
        title: const Text('Copy or not copy?'),
        content: const Text(
          'The data folder has changed.\n\n'
          'You can copy the content of the previous folder'
          ' to the new folder and overwrite its content.\n\n'
          'Or you can just set the folder and add some content to it manually\n'
          '(in which case you should do this now to load the new content when you exit the dialog).',
        ),
        actions: actions,
      ),
      barrierDismissible: false,
    );
  }
}

class PreferencesEditResult {
  final bool dataDirectoryChanged;

  PreferencesEditResult(this.dataDirectoryChanged);
}
