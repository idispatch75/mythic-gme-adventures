import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../persisters/persister.dart';

class GlobalSettingsService extends GetxService with SavableMixin {
  static const supportedSchemaVersion = 2;

  static const maxNumberOfItemsInList = 3;

  final int schemaVersion;
  bool allowChooseInLists;
  String meaningTablesLanguage;
  final Set<String> favoriteMeaningTables;
  List<String> characterTraitMeaningTables;
  bool allowUnlimitedListCount;
  final RxBool hideHelpButtons;
  int? saveTimestamp;

  GlobalSettingsService({
    this.schemaVersion = supportedSchemaVersion,
    this.allowChooseInLists = true,
    this.meaningTablesLanguage = 'en',
    Set<String>? favoriteMeaningTables,
    List<String>? characterTraitMeaningTables,
    this.allowUnlimitedListCount = false,
    bool hideHelpButtons = false,
    this.saveTimestamp,
  })  : favoriteMeaningTables = favoriteMeaningTables ?? {},
        characterTraitMeaningTables = characterTraitMeaningTables ?? [],
        hideHelpButtons = hideHelpButtons.obs;

  bool addMeaningTableFavorite(String id) {
    if (favoriteMeaningTables.add(id)) {
      requestSave();

      return true;
    }

    return false;
  }

  bool removeMeaningTableFavorite(String id) {
    if (favoriteMeaningTables.remove(id)) {
      requestSave();
      return true;
    }

    return false;
  }

  void setCharacterTraitMeaningTables(List<String> tableIds) {
    characterTraitMeaningTables = tableIds;
    requestSave();
  }

  JsonObj toJson() => {
        'schemaVersion': supportedSchemaVersion,
        'allowChooseInLists': allowChooseInLists,
        'meaningTablesLanguage': meaningTablesLanguage,
        'favoriteMeaningTables': favoriteMeaningTables.toList(),
        'characterTraitMeaningTables': characterTraitMeaningTables,
        'allowUnlimitedListCount': allowUnlimitedListCount,
        'hideHelpButtons': hideHelpButtons(),
        if (saveTimestamp != null) 'saveTimestamp': saveTimestamp,
      };

  GlobalSettingsService.fromJson(JsonObj json)
      : this(
          schemaVersion: json['schemaVersion'] ?? 1,
          allowChooseInLists: json['allowChooseInLists'] ?? true,
          meaningTablesLanguage: json['meaningTablesLanguage'] ?? 'en',
          favoriteMeaningTables:
              fromJsonValueList<String>(json['favoriteMeaningTables']).toSet(),
          characterTraitMeaningTables:
              fromJsonValueList<String>(json['characterTraitMeaningTables']),
          allowUnlimitedListCount: json['allowUnlimitedListCount'] ?? false,
          hideHelpButtons: json['hideHelpButtons'] ?? false,
          saveTimestamp: json['saveTimestamp'],
        );
}
