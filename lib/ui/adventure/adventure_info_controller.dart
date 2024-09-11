import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart' as rxdart;

import '../../helpers/datetime_extensions.dart';
import '../../helpers/string_extensions.dart';
import '../../persisters/adventure_persister.dart';
import '../../persisters/global_settings_persister.dart';
import '../../persisters/persister.dart';
import '../adventure_index/adventure_index_view.dart';
import '../characters/character.dart';
import '../global_settings/global_settings.dart';
import '../global_settings/global_settings_edit_view.dart';
import '../notes/note.dart';
import '../player_characters/player_character.dart';
import '../preferences/preferences.dart';
import '../scenes/scene.dart';
import '../threads/thread.dart';
import 'adventure.dart';
import 'adventure_edit_view.dart';

class AdventureInfoController extends GetxController {
  final hasError = false.obs;
  Object? error;

  final saving = false.obs;

  final Rx<String?> saveDate = Rx(null);

  StreamSubscription<SaveResult>? _saveResultsSubscription;
  Timer? _saveTickerTimer;

  @override
  void onInit() {
    super.onInit();

    // listen to save errors
    final globalSettingsPersister = Get.find<GlobalSettingsPersisterService>();
    final adventurePersister = Get.find<AdventurePersisterService>();
    _saveResultsSubscription = rxdart.MergeStream([
      globalSettingsPersister.saveResults,
      adventurePersister.saveResults,
    ]).listen((result) {
      if (result.isSuccess) {
        hasError(false);
      } else {
        error = result.error;
        hasError(true);
      }
    });

    // compute save date periodically
    saveDate.value = _getSaveDate();
    _saveTickerTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        saveDate.value = _getSaveDate();
      },
    );
  }

  @override
  void onClose() {
    _saveResultsSubscription?.cancel();
    _saveTickerTimer?.cancel();

    super.onClose();
  }

  Future<void> showIndex(BuildContext context) async {
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => AdventureIndexView()),
    );
  }

  Future<void> showAdventureSettings() async {
    final result = await Get.dialog<bool>(
      AdventureEditView(Get.find<AdventureService>()),
      barrierDismissible: false,
    );

    if (result ?? false) {
      await save();
    }
  }

  Future<void> showGlobalSettings() async {
    final result = await Get.dialog<bool>(
      GlobalSettingsEditView(Get.find<GlobalSettingsService>()),
      barrierDismissible: false,
    );

    if (result ?? false) {
      saving(true);
      try {
        await Get.find<GlobalSettingsPersisterService>().saveSettings();
      } catch (e) {
        // ignore, let the icon show the error
      }
      saving(false);
    }
  }

  void togglePhysicalDiceMode() {
    final preferences = Get.find<LocalPreferencesService>();

    preferences
        .enablePhysicalDiceMode(!preferences.enablePhysicalDiceMode.value);
  }

  Future<void> save() async {
    saving(true);
    try {
      await Get.find<AdventurePersisterService>().saveCurrentAdventure();
    } catch (e) {
      // ignore, let the icon show the error
    }
    saving(false);
  }

  Future<void> export() async {
    // adventure name
    final adventure = Get.find<AdventureService>();
    String text = adventure.name();

    String addTitle(String title) => text += '\n\n$title\n';
    String addItem(String name, String? summary, String? notes) {
      text += '\n$name';
      if (summary.isNotNullOrEmpty()) {
        text += '\n$summary';
      }
      if (notes.isNotNullOrEmpty()) {
        text += '\n$notes';
      }
      text += '\n';

      return text;
    }

    // scenes
    final scenes = Get.find<ScenesService>().scenes();
    if (scenes.isNotEmpty) {
      addTitle('Scenes');
      for (var scene in scenes.map((e) => e())) {
        addItem(scene.summary, null, scene.notes);
      }
    }

    // threads
    final threads = Get.find<ThreadsService>().items();
    if (threads.isNotEmpty) {
      addTitle('Threads');
      for (var item in threads.map((e) => e())) {
        addItem(item.name, item.summary, item.notes);
      }
    }

    // characters
    final characters = Get.find<CharactersService>().items();
    if (characters.isNotEmpty) {
      addTitle('Characters');
      for (var item in characters.map((e) => e())) {
        addItem(item.name, item.summary, item.notes);
      }
    }

    // player characters
    final playerCharacters =
        Get.find<PlayerCharactersService>().playerCharacters();
    if (playerCharacters.isNotEmpty) {
      addTitle('Player Characters');
      for (var item in playerCharacters.map((e) => e())) {
        addItem(item.name, null, item.notes);
      }
    }

    // notes
    final notes = Get.find<NotesService>().notes();
    if (notes.isNotEmpty) {
      addTitle('Notes');
      for (var item in notes.map((e) => e())) {
        addItem(item.title, null, item.content);
      }
    }

    // save the file
    final fileName = '${adventure.name()}.txt';

    if (GetPlatform.isDesktop) {
      final exportFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Adventure',
        fileName: fileName,
      );

      if (exportFile != null) {
        final file = File(exportFile);
        await file.writeAsString(text, flush: true);
      }
    } else {
      await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          data: utf8.encoder.convert(text),
          fileName: fileName,
        ),
      );
    }
  }

  static String? _getSaveDate() {
    final adventureSaveTimestamp = Get.find<AdventureService>().saveTimestamp();
    final globalSettingsSaveTimestamp =
        Get.find<GlobalSettingsService>().saveTimestamp;

    if (adventureSaveTimestamp == null && globalSettingsSaveTimestamp == null) {
      return null;
    }

    final saveTimestamp =
        ((adventureSaveTimestamp ?? 0) > (globalSettingsSaveTimestamp ?? 0)
                ? adventureSaveTimestamp
                : globalSettingsSaveTimestamp) ??
            0;

    final saveDate = DateTime.fromMillisecondsSinceEpoch(saveTimestamp);

    return 'Saved ${saveDate.elapsedFromNow()}';
  }
}
