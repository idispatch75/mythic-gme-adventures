import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart' as rxdart;

import '../../helpers/datetime_extensions.dart';
import '../../helpers/dialogs.dart';
import '../../helpers/string_extensions.dart';
import '../../helpers/utils.dart';
import '../../persisters/adventure_persister.dart';
import '../../persisters/global_settings_persister.dart';
import '../../persisters/persister.dart';
import '../adventure_index/adventure_index_view.dart';
import '../characters/character.dart';
import '../features/feature.dart';
import '../global_settings/global_settings.dart';
import '../global_settings/global_settings_edit_view.dart';
import '../keyed_scenes/keyed_scene.dart';
import '../notes/note.dart';
import '../player_characters/player_character.dart';
import '../preferences/preferences.dart';
import '../scenes/scene.dart';
import '../threads/thread.dart';
import '../widgets/rich_text_editor.dart';
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
    _saveResultsSubscription =
        rxdart.MergeStream([
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

    if (!preferences.physicalDiceModeExplained.value) {
      Dialogs.showAlert(
        title: 'Physical Dice Mode',
        message:
            'When Physical Dice Mode is enabled,'
            ' rolling in the App will not roll dice for you but open the lookup table for the roll.'
            ' You can then roll physical dice and lookup the result there.',
      );

      preferences.physicalDiceModeExplained(true);
    }

    preferences.enablePhysicalDiceMode(
      !preferences.enablePhysicalDiceMode.value,
    );
  }

  Future<String?> save() async {
    String? fileContent;

    saving(true);
    try {
      fileContent = await Get.find<AdventurePersisterService>()
          .saveCurrentAdventure();
    } catch (e) {
      // ignore, let the icon show the error
    }
    saving(false);

    return fileContent;
  }

  Future<void> backup() async {
    final fileContent = await save();
    if (fileContent == null) return;

    final adventure = Get.find<AdventureService>();
    final fileName =
        '${adventure.name()}-${DateFormat('y-MM-dd_HH-mm').format(DateTime.now())}.json';

    await saveTextFile(
      fileContent,
      fileName: fileName,
      dialogTitle: 'Backup Adventure',
    );
  }

  Future<void> exportAsText() async {
    String? richTextToPlainText(String? richText) {
      return RichTextEditorController(
        richText,
      ).quill.document.toPlainText().trimRight();
    }

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
      for (var item in scenes.map((e) => e())) {
        addItem(item.summary, null, richTextToPlainText(item.notes));
      }
    }

    // keyed scenes
    final keyedScenes = Get.find<KeyedScenesService>().scenes();
    if (keyedScenes.isNotEmpty) {
      addTitle('Keyed Scenes');
      for (var item in keyedScenes.map((e) => e())) {
        addItem(item.trigger, null, item.event);
      }
    }

    // threads
    final threads = Get.find<ThreadsService>().items();
    if (threads.isNotEmpty) {
      addTitle('Threads');
      for (var item in threads.map((e) => e()).sorted((a, b) => a.id - b.id)) {
        addItem(item.name, item.summary, richTextToPlainText(item.notes));
      }
    }

    // characters
    final characters = Get.find<CharactersService>().items();
    if (characters.isNotEmpty) {
      addTitle('Characters');
      for (var item
          in characters.map((e) => e()).sorted((a, b) => a.id - b.id)) {
        addItem(item.name, item.summary, richTextToPlainText(item.notes));
      }
    }

    // features
    final features = Get.find<FeaturesService>().features();
    if (features.isNotEmpty) {
      addTitle('Features');
      for (var item in features.map((e) => e()).sorted((a, b) => a.id - b.id)) {
        addItem(item.name, null, richTextToPlainText(item.notes));
      }
    }

    // player characters
    final playerCharacters = Get.find<PlayerCharactersService>()
        .playerCharacters();
    if (playerCharacters.isNotEmpty) {
      addTitle('Player Characters');
      for (var item in playerCharacters.map((e) => e())) {
        addItem(item.name, null, richTextToPlainText(item.notes));
      }
    }

    // notes
    final notes = Get.find<NotesService>().notes();
    if (notes.isNotEmpty) {
      addTitle('Notes');
      for (var item in notes.map((e) => e())) {
        addItem(item.title, null, richTextToPlainText(item.content));
      }
    }

    // save the file
    final fileName = '${adventure.name()}.txt';

    await saveTextFile(
      text,
      fileName: fileName,
      dialogTitle: 'Export Adventure',
    );
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
