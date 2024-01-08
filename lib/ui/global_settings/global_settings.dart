import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../../persisters/persister.dart';

class GlobalSettingsService extends GetxService with SavableMixin {
  bool allowChooseInLists;
  String meaningTablesLanguage;
  final Set<String> favoriteMeaningTables;
  int? saveTimestamp;

  GlobalSettingsService({
    this.allowChooseInLists = true,
    this.meaningTablesLanguage = 'en',
    Set<String>? favoriteMeaningTables,
    this.saveTimestamp,
  }) : favoriteMeaningTables = favoriteMeaningTables ?? {};

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

  Map<String, dynamic> toJson() => {
        'allowChooseInLists': allowChooseInLists,
        'meaningTablesLanguage': meaningTablesLanguage,
        'favoriteMeaningTables': favoriteMeaningTables.toList(),
        if (saveTimestamp != null) 'saveTimestamp': saveTimestamp,
      };

  GlobalSettingsService.fromJson(Map<String, dynamic> json)
      : this(
          allowChooseInLists: json['allowChooseInLists'] ?? true,
          meaningTablesLanguage: json['meaningTablesLanguage'] ?? 'en',
          favoriteMeaningTables:
              fromJsonValueList<String>(json['favoriteMeaningTables']).toSet(),
          saveTimestamp: json['saveTimestamp'],
        );
}
