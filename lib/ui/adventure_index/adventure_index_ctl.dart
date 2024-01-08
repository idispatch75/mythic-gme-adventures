import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../helpers/datetime_extensions.dart';
import '../../helpers/dialogs.dart';
import '../../helpers/inline_link.dart';
import '../../persisters/adventure_persister.dart';
import '../../persisters/global_settings_persister.dart';
import '../../persisters/meaning_tables_persister.dart';
import '../../storages/data_storage.dart';
import '../../storages/google_auth.dart';
import '../adventure/adventure.dart';
import '../adventure/adventure_view.dart';
import '../global_settings/global_settings.dart';
import '../meaning_tables/meaning_table.dart';
import '../preferences/preferences.dart';
import '../preferences/preferences_edit_view.dart';
import 'adventure_index.dart';

class IndexAdventureVM {
  final IndexAdventure source;
  final String saveDateText;

  IndexAdventureVM(this.source, this.saveDateText);
}

class AdventureIndexController extends GetxController {
  final status = RxStatus.loading().obs;

  final isMeaningTableUploading = false.obs;
  final isMeaningTableDownloading = false.obs;
  final meaningTableTransferProgress = 0.obs;

  final isSynchronizing = false.obs;

  List<IndexAdventureVM> adventures = [];

  @override
  Future<void> onInit() async {
    super.onInit();

    await _loadAdventures();
  }

  Future<void> reload() {
    return _loadAdventures();
  }

  Future<void> enableGoogleStorage(bool value) async {
    Get.find<LocalPreferencesService>().enableGoogleStorage(value);
    Get.find<MeaningTablesPersisterService>().needsLoading = true;

    await _loadAdventures();
  }

  Future<void> disableLocalStorage(bool value) async {
    Get.find<LocalPreferencesService>().enableLocalStorage(!value);
    Get.find<MeaningTablesPersisterService>().needsLoading = true;

    await _loadAdventures();
  }

  Future<void> googleSignOut() async {
    await Get.find<GoogleAuthService>().authManager.signOut();

    await enableGoogleStorage(false);
  }

  Future<void> showPreferences() async {
    final result = await Get.dialog<PreferencesEditResult>(
      const PreferencesEditView(),
      barrierDismissible: false,
    );

    if (result != null && result.dataDirectoryChanged) {
      await reload();
    }
  }

  Future<void> showAdventure(
    BuildContext context,
    IndexAdventureVM adventure,
  ) {
    return Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AdventureView(adventure.source.id),
      ),
    );
  }

  Future<void> addAdventure(AdventureService adventure) async {
    status.value = RxStatus.loading();

    try {
      await Get.find<AdventurePersisterService>().saveNewAdventure(adventure);
    } catch (e) {
      _handleError('save', e);

      return;
    }

    await _loadAdventures();
  }

  Future<void> deleteAdventure(IndexAdventureVM adventure) async {
    if (await showConfirmationDialog(
      title: 'Delete Adventure',
      message: 'Delete the Adventure "${adventure.source.name}"?',
    )) {
      status.value = RxStatus.loading();

      try {
        await Get.find<AdventurePersisterService>()
            .deleteAdventure(adventure.source.id);
      } catch (e) {
        _handleError('delete', e);

        return;
      }

      await _loadAdventures();
    }
  }

  Future<void> uploadMeaningTables() async {
    // ask confirmation
    if (!await showConfirmationDialog(
      title: 'Upload Meaning Tables',
      message: 'You will overwrite the custom Meaning Tables'
          ' in your online storage.\nContinue?',
    )) {
      return;
    }

    // pick a source directory
    String? localDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Meaning Tables folder',
      lockParentWindow: true,
    );
    if (localDirectory == null) {
      return;
    }

    // upload the tables
    try {
      meaningTableTransferProgress.value = 0;
      isMeaningTableUploading.value = true;

      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.pushToRemote(
        localDirectory,
        meaningTableTransferProgress,
      );

      meaningTables.needsLoading = true;
    } catch (e) {
      _handleError('upload', e);
    }

    isMeaningTableUploading.value = false;
  }

  Future<void> downloadMeaningTables(BuildContext context) async {
    final spanStyle = Theme.of(context).textTheme.bodyMedium;

    // ask confirmation
    if (!await showConfirmationDialog(
      title: 'Download Meaning Tables',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('You will overwrite the custom Meaning Tables'
              ' in your local storage.\nContinue?\n\n'
              'Note that only the files uploaded by the Application are visible by the Application.\n'
              'You must first upload the Meaning Tables to be able to download them.'
              ' If you put them on your online storage yourself, nothing will be downloaded.'),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'More info in the ', style: spanStyle),
                getInlineLink(
                  text: 'User Manual',
                  url:
                      'https://idispatch75.github.io/mythic-gme-adventures/user_manual/',
                ),
                TextSpan(text: '.', style: spanStyle),
              ],
            ),
          ),
        ],
      ),
    )) {
      return;
    }

    // download to local storage
    try {
      meaningTableTransferProgress.value = 0;
      isMeaningTableDownloading.value = true;

      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.pullFromRemote(meaningTableTransferProgress);
    } catch (e) {
      _handleError('download', e);
    }

    isMeaningTableDownloading.value = false;
  }

  Future<void> synchronizeAdventures() async {
    if (await showConfirmationDialog(
      title: 'Synchronize storages',
      message: 'Update the local and online storages'
          ' with the most recent adventure versions?',
    )) {
      try {
        isSynchronizing.value = true;

        await Get.find<AdventurePersisterService>().synchronizeAdventures();
      } catch (e) {
        _handleError('synchronize', e);

        return;
      } finally {
        isSynchronizing.value = false;
      }

      await _loadAdventures();
    }
  }

  Future<void> restoreAdventure(
    String filePath,
    IndexAdventureVM adventure,
  ) async {
    if (!await showConfirmationDialog(
      title: 'Restore Adventure',
      message: 'Replace the content of this Adventure'
          ' with the selected file?',
    )) {
      return;
    }

    // ask confirmation if the adventure IDs do not match
    try {
      final content = await File(filePath).readAsString();

      final json = jsonDecode(content) as Map<String, dynamic>;
      final adventureId = json['id'] as int?;
      if (adventureId == null) {
        throw Exception('Invalid Adventure file');
      }

      if (adventureId != adventure.source.id) {
        if (!await showConfirmationDialog(
          title: 'Adventure mismatch',
          message: 'The file you selected does not match the Adventure.\n'
              'Continue?',
        )) {
          return;
        }
      }
    } catch (e) {
      showAlertDialog(
        title: 'Invalid Adventure',
        message: 'The selected file does not contain a valid Adventure.',
      );
    }

    // restore
    try {
      status.value = RxStatus.loading();

      await Get.find<AdventurePersisterService>().restoreAdventure(
        filePath,
        adventure.source.id,
      );
    } catch (e) {
      _handleError('save', e);
    } finally {
      status.value = RxStatus.success();
    }

    await _loadAdventures();
  }

  static final DateFormat _dateFormat =
      DateFormat.yMMMEd().addPattern("'at'").add_jms();
  static final DateFormat _timeFormat = DateFormat.jms();

  Future<void> _loadAdventures() async {
    status.value = RxStatus.loading();

    try {
      await Get.find<GlobalSettingsPersisterService>().loadSettings();
      await Get.find<AdventurePersisterService>().loadIndex();
      Get.find<MeaningTablesService>().language.value =
          Get.find<GlobalSettingsService>().meaningTablesLanguage;
    } catch (e) {
      _handleError('load', e);

      return;
    }

    final preferences = Get.find<LocalPreferencesService>();
    final hasBothStorages =
        preferences.enableGoogleStorage() && preferences.enableLocalStorage();

    const maxInt = 9223372036854775807;
    adventures = Get.find<AdventureIndexService>()
        .adventures
        .where((e) => !e.isDeleted)
        .sorted(
            (a, b) => (b.saveTimestamp ?? maxInt) - (a.saveTimestamp ?? maxInt))
        .map((adventure) {
      // compute the save date text
      String saveDateText;
      if (adventure.saveTimestamp != null) {
        final saveDate =
            DateTime.fromMillisecondsSinceEpoch(adventure.saveTimestamp!);
        final now = DateTime.now();
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        if (now.isSameDay(saveDate)) {
          saveDateText = 'today at ${_timeFormat.format(saveDate)}';
        } else if (yesterday.day == saveDate.day &&
            yesterday.month == saveDate.month &&
            yesterday.year == saveDate.year) {
          saveDateText = 'yesterday at ${_timeFormat.format(saveDate)}';
        } else {
          saveDateText = _dateFormat.format(saveDate);
        }

        String saveDateSource;
        if (!hasBothStorages ||
            adventure.localSaveTimestamp == adventure.remoteSaveTimestamp) {
          saveDateSource = '';
        } else if (adventure.localSaveTimestamp >
            adventure.remoteSaveTimestamp) {
          saveDateSource = 'locally ';
        } else {
          saveDateSource = 'online ';
        }

        saveDateText = 'Saved $saveDateSource$saveDateText';
      } else {
        saveDateText = 'Not saved yet';
      }

      return IndexAdventureVM(adventure, saveDateText);
    }).toList();

    status.value = adventures.isEmpty ? RxStatus.empty() : RxStatus.success();
  }

  void _handleError(String action, Object error) {
    String message;

    if (error is LocalStorageException) {
      message =
          'Failed to $action "${error.filePath}" locally: ${error.error}.\n\n';
      switch (action) {
        case 'load':
          message += 'If you have an up to date online save,'
              ' you may want to delete the file locally,'
              ' or you can disable local storage.';
          break;

        case 'save':
          message += 'Check the access rights on the save directory,'
              ' or, if you can save online,'
              ' you can disable local storage.';
          break;

        case 'delete':
          message += 'Check the access rights on the save directory,'
              ' or delete the file manually.';
          break;

        case 'upload':
          message += 'Check the file can be read.';

        case 'download':
          message += 'Check the access rights on the download directory.';
          break;
      }
    } else if (error is RemoteStorageException) {
      final actionText = switch (action) {
        'save' => '$action "${error.filePath}" to',
        'delete' => '$action "${error.filePath}" from',
        'load' => '$action "${error.filePath}" from',
        'upload' => '$action "${error.filePath}" to',
        'download' => '$action "${error.filePath}" from',
        _ => '$action "${error.filePath}" from'
      };

      message = 'Failed to $actionText ${error.provider}.\n\n';

      if (error is RemoteStorageAuthenticationException) {
        message += 'The authentication is no more valid.\n'
            'Please toggle ${error.provider} access to retry a silent authentication,'
            ' or sign out and enable ${error.provider} again.';
      } else if (error is RemoteStorageNetworkException) {
        message += '${error.provider} could not be contacted.\n'
            'Please check your internet access.';
      } else if (error is RemoteStorageOperationException) {
        message += '${error.provider} refused to perform the operation:'
            ' ${error.error}.';
      }
    } else {
      message = 'Failed to $action data.\n\n'
          'An unexpected error occurred: $error.';
    }

    if (action == 'load') {
      status.value = RxStatus.error(message);
    } else {
      showAlertDialog(title: 'Failed to $action', message: message);

      status.value = RxStatus.success();
    }
  }
}
