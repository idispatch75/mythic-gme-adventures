import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../helpers/datetime_extensions.dart';
import '../../helpers/dialogs.dart';
import '../../helpers/json_utils.dart';
import '../../helpers/utils.dart';
import '../../persisters/adventure_persister.dart';
import '../../persisters/global_settings_persister.dart';
import '../../persisters/meaning_tables_persister.dart';
import '../../persisters/persister.dart';
import '../../storages/data_storage.dart';
import '../../storages/google_auth_service.dart';
import '../../storages/local_storage.dart';
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

  const IndexAdventureVM(this.source, this.saveDateText);
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
      handleError('save', e);

      return;
    }

    await _loadAdventures();
  }

  Future<void> deleteAdventure(IndexAdventureVM adventure) async {
    if (await Dialogs.showConfirmation(
      title: 'Delete Adventure?',
      message:
          'The Adventure "${adventure.source.name}" will be permanently deleted.',
    )) {
      status.value = RxStatus.loading();

      try {
        await Get.find<AdventurePersisterService>().deleteAdventure(
          adventure.source.id,
        );
      } catch (e) {
        handleError('delete', e);

        return;
      }

      await _loadAdventures();
    }
  }

  Future<void> synchronizeAdventures() async {
    if (await Dialogs.showConfirmation(
      title: 'Synchronize storages?',
      message:
          'This updates the local and online storages'
          ' with the most recent adventure versions.',
    )) {
      try {
        isSynchronizing.value = true;

        await Get.find<AdventurePersisterService>().synchronizeAdventures();
      } catch (e) {
        handleError('synchronize', e);

        return;
      } finally {
        isSynchronizing.value = false;
      }

      await _loadAdventures();
    }
  }

  Future<void> restoreAdventure(
    JsonObj json,
    IndexAdventureVM adventure,
  ) async {
    if (!await Dialogs.showConfirmation(
      title: 'Restore Adventure?',
      message:
          'This will replace the content of this Adventure'
          ' with the selected file.',
    )) {
      return;
    }

    // ask confirmation if the adventure IDs do not match
    try {
      final adventureId = json['id'] as int?;
      if (adventureId == null) {
        throw Exception('Invalid Adventure file');
      }

      if (adventureId != adventure.source.id) {
        if (!await Dialogs.showConfirmation(
          title: 'Adventure mismatch',
          message:
              'The file you selected does not match the Adventure.'
              ' This may be normal if you restore into a newly created adventure.\n'
              'Continue?',
        )) {
          return;
        }
      }
    } catch (e) {
      await Dialogs.showAlert(
        title: 'Invalid Adventure',
        message: 'The selected file does not contain a valid Adventure.',
      );
    }

    // restore
    try {
      status.value = RxStatus.loading();

      await Get.find<AdventurePersisterService>().restoreAdventure(
        json,
        adventure.source.id,
      );
    } catch (e) {
      handleError('save', e);
    } finally {
      status.value = RxStatus.success();
    }

    await _loadAdventures();
  }

  Future<void> backupLocalAdventures() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: 'Backup local Adventures?',
      message:
          'This will create a zip file containing all the Adventures'
          ' in your local storage.\n'
          'You can pick Adventures to restore from there when needed.',
    )) {
      return;
    }

    // create the archive
    final archive = Archive();

    final storage = LocalStorage();
    await storage.loadJsonFiles(
      [AdventurePersister.directory],
      (filePath, jsonContent) {
        if (filePath.length == 1) {
          // we store only the files at the root

          // use .string() constructor when fixed
          // https://github.com/brendan-duncan/archive/issues/354
          final content = utf8.encode(jsonContent);
          archive.addFile(ArchiveFile(filePath[0], content.length, content));
        }

        return Future.value();
      },
    );

    final zipContent = ZipEncoder().encode(
      archive,
      level: DeflateLevel.bestCompression,
    );

    // save the archive
    return saveBinaryFile(
      Uint8List.fromList(zipContent),
      fileName:
          'Mythic_GME_Adventures-backup-${DateFormat('y-MM-dd_HH-mm').format(DateTime.now())}.zip',
      dialogTitle: 'Adventures backup',
    );
  }

  Future<void> importLocalCustomMeaningTables() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: 'Import Custom Meaning Tables?',
      message:
          'This will delete the Custom Meaning Tables'
          ' in your local storage and import the selected ones.\n\n'
          'You may need to restart the application for the changes to take effect.',
      userManualAnchor: 'custom-meaning-tables',
    )) {
      return;
    }

    // pick a zip file
    final zipContent = await pickFileAsBytes(
      dialogTitle: 'Meaning Tables Zip file',
      extension: 'zip',
    );
    if (zipContent == null) {
      return;
    }

    // import the tables
    try {
      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.importZipToLocal(zipContent);

      await Dialogs.showAlert(
        title: 'Import successful',
        message:
            'The Custom Meaning Tables were imported into your local storage.',
      );
    } catch (e) {
      handleError('import', e);
    }
  }

  Future<void> deleteLocalCustomMeaningTables() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: 'Delete Custom Meaning Tables?',
      message:
          'This will permanently delete the Custom Meaning Tables'
          ' in your local storage.\n\n'
          'You may need to restart the application for the changes to take effect.',
    )) {
      return;
    }

    // delete
    try {
      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.deleteLocal();

      await Dialogs.showAlert(
        title: 'Deletion successful',
        message:
            'The Custom Meaning Tables in your local storage were deleted.',
      );
    } catch (e) {
      handleError('_delete_meaning_tables', e);
    }
  }

  Future<void> downloadMeaningTables() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: 'Download Custom Meaning Tables?',
      message:
          'This will delete the Custom Meaning Tables'
          ' in your local storage and download the meaning tables from the remote storage.\n'
          'You may need to restart the application for the changes to take effect.\n\n'
          'Note that only the files uploaded by the Application are visible by the Application.\n'
          'You must first upload the Meaning Tables to be able to download them.'
          ' If you put them in your online storage via Google Drive web site, nothing will be downloaded.',
      userManualAnchor: 'online-storage',
    )) {
      return;
    }

    // download to local storage
    try {
      meaningTableTransferProgress.value = 0;
      isMeaningTableDownloading.value = true;

      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.importFromRemote(meaningTableTransferProgress);
    } catch (e) {
      handleError('download', e);
    }

    isMeaningTableDownloading.value = false;
  }

  static final DateFormat _dateFormat = DateFormat.yMMMEd()
      .addPattern("'at'")
      .add_jms();
  static final DateFormat _timeFormat = DateFormat.jms();

  Future<void> _loadAdventures() async {
    status.value = RxStatus.loading();

    try {
      await Get.find<GlobalSettingsPersisterService>().loadSettings();
      await Get.find<AdventurePersisterService>().loadIndex();
      Get.find<MeaningTablesService>().language.value =
          Get.find<GlobalSettingsService>().meaningTablesLanguage;
    } on UnsupportedSchemaVersionException catch (e) {
      handleUnsupportedSchemaVersion(e).ignore();

      return;
    } catch (e) {
      handleError('load', e);

      return;
    }

    final preferences = Get.find<LocalPreferencesService>();
    final hasBothStorages =
        preferences.enableGoogleStorage() && preferences.enableLocalStorage();

    final maxInt = double.maxFinite.toInt(); // works for web and io
    adventures = Get.find<AdventureIndexService>().adventures
        .where((e) => !e.isDeleted)
        .sorted(
          (a, b) => (b.saveTimestamp ?? maxInt) - (a.saveTimestamp ?? maxInt),
        )
        .map((adventure) {
          // compute the save date text
          String saveDateText;
          if (adventure.saveTimestamp != null) {
            final saveDate = DateTime.fromMillisecondsSinceEpoch(
              adventure.saveTimestamp!,
            );
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
        })
        .toList();

    status.value = adventures.isEmpty ? RxStatus.empty() : RxStatus.success();
  }

  void handleError(String action, Object error) {
    String message;
    if (error is LocalStorageNotSupportedException) {
      message =
          'Local storage is not supported by your browser.\n\n'
          'You must Use Google Drive and Disable local storage.';
    } else if (error is LocalStorageException) {
      message =
          'Failed to $action "${error.filePath}" locally: ${error.error}.\n\n';
      switch (action) {
        case 'load':
          message +=
              'If you have an up to date online save,'
              ' you may want to delete the file locally,'
              ' or you can disable local storage.';
          break;

        case 'save':
          message +=
              'Check the access rights on the save directory,'
              ' or, if you can save online,'
              ' you can disable local storage.';
          break;

        case 'delete':
          message +=
              'Check the access rights on the save directory,'
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
        _ => '$action "${error.filePath}" from',
      };

      message = 'Failed to $actionText ${error.provider}.\n\n';

      if (error is RemoteStorageAuthenticationException) {
        message +=
            'The authentication is no more valid.\n'
            'Please toggle ${error.provider} access to retry a silent authentication,'
            ' or sign out and enable ${error.provider} again.';
      } else if (error is RemoteStorageNetworkException) {
        message +=
            '${error.provider} could not be contacted.\n'
            'Please check your internet access.';
      } else if (error is RemoteStorageOperationException) {
        message +=
            '${error.provider} refused to perform the operation:'
            ' ${error.error}.';
      }
    } else {
      message =
          'Failed to $action data.\n\n'
          'An unexpected error occurred: $error.';
    }

    if (action == 'load') {
      status.value = RxStatus.error(message);
    } else {
      Dialogs.showAlert(title: 'Failed to $action', message: message);

      status.value = RxStatus.success();
    }
  }
}
