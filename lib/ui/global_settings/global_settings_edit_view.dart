import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../meaning_tables/meaning_table.dart';
import '../widgets/boolean_setting.dart';
import '../widgets/edit_dialog.dart';
import '../widgets/sub_label.dart';
import 'global_settings.dart';

class GlobalSettingsEditController extends GetxController {
  static const _languages = {
    'en': 'English',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'es': 'Español',
    'pt': 'Português',
    'ru': 'Русский',
    'nl': 'Nederlands',
    'cs': 'Czeski',
    'pl': 'Polski',
  };

  final meaningTableLanguages = <String, String>{};

  @override
  void onInit() async {
    super.onInit();

    final languageCodes = Get.find<MeaningTablesService>().languageCodes;

    for (var code in languageCodes) {
      final languageName = _languages[code];
      if (languageName != null) {
        meaningTableLanguages[code] = languageName;
      } else {
        meaningTableLanguages[code] = code;
      }
    }
  }
}

class GlobalSettingsEditView extends HookWidget {
  final GlobalSettingsService _settings;

  GlobalSettingsEditView(this._settings, {super.key}) {
    Get.put(GlobalSettingsEditController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GlobalSettingsEditController>();
    final languageMenuEntries = controller.meaningTableLanguages.entries
        .map((e) => DropdownMenuEntry<String>(value: e.key, label: e.value))
        .toList();

    final allowChooseInLists = _settings.allowChooseInLists.obs;
    final allowUnlimitedListCount = _settings.allowUnlimitedListCount.obs;
    final hideHelpButtons = _settings.hideHelpButtons().obs;
    final meaningTablesLanguage = _settings.meaningTablesLanguage.obs;
    if (!controller.meaningTableLanguages
        .containsKey(meaningTablesLanguage())) {
      meaningTablesLanguage.value = 'en';
    }

    return EditDialog<bool>(
      itemTypeLabel: 'Global Settings',
      canDelete: false,
      onSave: () {
        _settings.allowChooseInLists = allowChooseInLists();
        _settings.allowUnlimitedListCount = allowUnlimitedListCount();
        _settings.hideHelpButtons.value = hideHelpButtons();
        _settings.meaningTablesLanguage = meaningTablesLanguage();
        Get.find<MeaningTablesService>().language.value =
            _settings.meaningTablesLanguage;

        return Future.value(true);
      },
      body: Container(
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // allow to roll "Choose"
            BooleanSetting(
              setting: allowChooseInLists,
              text:
                  'Allow to roll "Choose" in the Characters and Threads lists',
              subtext:
                  'If unchecked, rolling will always pick an item in the list.',
            ),

            // allow unlimited list count
            BooleanSetting(
              withTopPadding: true,
              setting: allowUnlimitedListCount,
              text: 'Allow unlimited counter in Characters/Threads Lists',
              subtext: 'The rules recommend not having more than'
                  ' ${GlobalSettingsService.maxNumberOfItemsInList} identical items in a List.'
                  ' This is enforced unless you check this option.',
            ),

            // hide help buttons
            BooleanSetting(
              withTopPadding: true,
              setting: hideHelpButtons,
              text: 'Hide Help buttons',
              subtext: 'Hides the Help buttons in the application.'
                  ' You can still access the Help in the Adventure menu.',
            ),

            // meaning tables language
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(
                    () => DropdownMenu<String>(
                      requestFocusOnTap: false,
                      width: 250,
                      initialSelection: meaningTablesLanguage(),
                      label: const Text('Meaning Tables Language'),
                      dropdownMenuEntries: languageMenuEntries,
                      onSelected: (value) {
                        meaningTablesLanguage.value = value ?? 'en';
                      },
                    ),
                  ),
                  const SubLabel(
                    'This applies to the Meaning Tables only,'
                    ' not the whole application.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
