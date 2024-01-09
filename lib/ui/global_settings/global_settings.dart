import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../../persisters/persister.dart';

class GlobalSettingsService extends GetxService with SavableMixin {
  bool allowChooseInLists;
  String meaningTablesLanguage;
  final Set<String> favoriteMeaningTables;
  List<String> characterTraitMeaningTables;
  int? saveTimestamp;

  GlobalSettingsService({
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

  Map<String, dynamic> toJson() => {
        'allowChooseInLists': allowChooseInLists,
        'meaningTablesLanguage': meaningTablesLanguage,
        'favoriteMeaningTables': favoriteMeaningTables.toList(),
        'characterTraitMeaningTables': characterTraitMeaningTables,
        if (saveTimestamp != null) 'saveTimestamp': saveTimestamp,
      };

  GlobalSettingsService.fromJson(Map<String, dynamic> json)
      : this(
          allowChooseInLists: json['allowChooseInLists'] ?? true,
          meaningTablesLanguage: json['meaningTablesLanguage'] ?? 'en',
          favoriteMeaningTables:
              fromJsonValueList<String>(json['favoriteMeaningTables']).toSet(),
          characterTraitMeaningTables:
              fromJsonValueList<String>(json['characterTraitMeaningTables']),
          saveTimestamp: json['saveTimestamp'],
        );
}
