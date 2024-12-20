import 'package:get/get.dart';

import '../../helpers/json_utils.dart';
import '../../persisters/persister.dart';

class GlobalSettingsService extends GetxService with SavableMixin {
  static const supportedSchemaVersion = 1;

  final int schemaVersion;
  bool allowChooseInLists;
  String meaningTablesLanguage;
  final Set<String> favoriteMeaningTables;
  List<String> characterTraitMeaningTables;
  int? saveTimestamp;

  GlobalSettingsService({
    this.schemaVersion = supportedSchemaVersion,
    this.allowChooseInLists = true,
    this.meaningTablesLanguage = 'en',
    Set<String>? favoriteMeaningTables,
    List<String>? characterTraitMeaningTables,
    this.saveTimestamp,
  })  : favoriteMeaningTables = favoriteMeaningTables ?? {},
        characterTraitMeaningTables = characterTraitMeaningTables ?? [];

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
          saveTimestamp: json['saveTimestamp'],
        );
}
